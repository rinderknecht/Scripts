#!/usr/bin/env bash
#
# Rotating incremental snapshots using rsync --link-dest.
# Requires Bash 4.4+, rsync, and flock (util-linux); mountpoint is needed
# only with --require-mount.
#
# Layout: PREFIX/NAME.00 (newest) ... PREFIX/NAME.NN (oldest).
# Each source is stored under its basename inside a snapshot.
#
# version: 2

set -Eeuo pipefail
umask 077

if (( BASH_VERSINFO[0] < 4 || (BASH_VERSINFO[0] == 4 && BASH_VERSINFO[1] < 4) )); then
  printf '%s: error: Bash 4.4 or newer is required\n' "${0##*/}" >&2
  exit 1
fi

program=${0##*/}
quiet=0 verbose=0 dry_run=0 checksum=0 one_fs=0 allow_partial=0
keep=31
min_free_mib=0
prefix= name= require_mount=
sources=()
excludes=()
staging=0

usage() {
  cat <<EOF
Usage: $program -p SNAPSHOT_DIR -f NAME -m SOURCE [-m SOURCE ...] [OPTIONS]

Create rotating, hard-link-based incremental snapshots.

Required:
  -p, --prefix DIR        Existing directory in which snapshots are stored
  -f, --filename NAME     Snapshot name; snapshots are NAME.00, NAME.01, ...
  -m, --master PATH       File or directory to back up (repeatable)

Options:
  -u, --keep NUM          Snapshots to retain, 1-99 (default: 31; use >= 2)
  -x, --exclude PATTERN   rsync exclude pattern (repeatable)
      --one-file-system   Do not cross filesystem boundaries inside sources
      --checksum          Compare file contents instead of size+mtime (slow)
      --require-mount DIR Refuse to run unless DIR is a mount point and
                          the snapshot directory is inside it
      --min-free MiB      Refuse to run with less free space on the target
      --allow-partial     Accept rsync exit 23 (some files unreadable)
  -n, --dry-run           Show what changed since the newest snapshot
  -q, --quiet             Suppress progress messages
  -v, --verbose           Show rsync itemized changes
  -h, --help              Show this help

Examples:
  $program -p /mnt/backup -f home -m /home/alice -u 14 \\
      --require-mount /mnt/backup --one-file-system -x '.cache/'

Source basenames must be unique, and the snapshot directory and sources must
not contain one another. Never modify files inside snapshots: hard-linked
files are shared between snapshots.
EOF
}

die()  { printf '%s: error: %s\n' "$program" "$*" >&2; exit 1; }
warn() { printf '%s: warning: %s\n' "$program" "$*" >&2; }
info() { if (( ! quiet )); then printf '%s %s\n' "$(date '+%F %T')" "$*"; fi; }
need_arg() { (( $# >= 2 )) || die "missing argument for $1"; }

# Turn "--opt=value" into "--opt value" for options that take a value.
args=()
for arg in "$@"; do
  case $arg in
    --prefix=*|--filename=*|--master=*|--keep=*|--exclude=*|\
    --require-mount=*|--min-free=*)
      args+=("${arg%%=*}" "${arg#*=}") ;;
    *) args+=("$arg") ;;
  esac
done
set -- "${args[@]}"

while (( $# )); do
  case $1 in
    -p|--prefix)
      need_arg "$@"; [[ -z $prefix ]] || die "$1 specified more than once"
      prefix=$2; shift 2 ;;
    -f|--filename)
      need_arg "$@"; [[ -z $name ]] || die "$1 specified more than once"
      name=$2; shift 2 ;;
    -m|--master)       need_arg "$@"; sources+=("$2"); shift 2 ;;
    -u|--keep)         need_arg "$@"; keep=$2; shift 2 ;;
    -x|--exclude)      need_arg "$@"; excludes+=("$2"); shift 2 ;;
    --require-mount)   need_arg "$@"; require_mount=$2; shift 2 ;;
    --min-free)        need_arg "$@"; min_free_mib=$2; shift 2 ;;
    --one-file-system) one_fs=1; shift ;;
    --checksum)        checksum=1; shift ;;
    --allow-partial)   allow_partial=1; shift ;;
    -n|--dry-run)      dry_run=1; shift ;;
    -q|--quiet)        quiet=1; shift ;;
    -v|--verbose)      verbose=1; shift ;;
    -h|--help)         usage; exit 0 ;;
    --)  shift; (( $# == 0 )) || die "unexpected positional arguments: $*" ;;
    -*)  die "unknown option: $1" ;;
    *)   die "unexpected positional argument: $1" ;;
  esac
done

[[ -n $prefix ]] || die "specify a snapshot directory with --prefix"
[[ -n $name ]] || die "specify a snapshot name with --filename"
(( ${#sources[@]} > 0 )) || die "specify at least one source with --master"
[[ $keep =~ ^[0-9]{1,2}$ ]] || die "--keep must be an integer from 1 to 99"
keep=$((10#$keep))
(( keep >= 1 )) || die "--keep must be from 1 to 99"
[[ $min_free_mib =~ ^[0-9]{1,9}$ ]] || die "--min-free must be a non-negative integer (MiB)"
min_free_mib=$((10#$min_free_mib))
[[ $name != "." && $name != ".." && $name != */* ]] ||
  die "--filename must be a simple name, not a path"
[[ -d $prefix ]] || die "snapshot directory does not exist: $prefix"
command -v rsync >/dev/null 2>&1 || die "rsync is not installed"
command -v flock >/dev/null 2>&1 || die "flock (util-linux) is not installed"
(( keep >= 2 )) || warn "--keep 1 leaves no good snapshot while the new one is committed"

prefix=$(cd -- "$prefix" && pwd -P)

if [[ -n $require_mount ]]; then
  command -v mountpoint >/dev/null 2>&1 || die "mountpoint (util-linux) is not installed"
  require_mount=$(cd -- "$require_mount" 2>/dev/null && pwd -P) ||
    die "cannot access --require-mount directory"
  mountpoint -q -- "$require_mount" ||
    die "not a mount point (is the backup drive mounted?): $require_mount"
  [[ $prefix == "$require_mount" || $prefix == "$require_mount/"* ]] ||
    die "snapshot directory $prefix is not inside $require_mount"
fi

if (( min_free_mib > 0 )); then
  avail_kib=$(df -Pk -- "$prefix" | awk 'NR==2 {print $4}')
  [[ $avail_kib =~ ^[0-9]+$ ]] || die "cannot determine free space on $prefix"
  (( avail_kib / 1024 >= min_free_mib )) ||
    die "less than $min_free_mib MiB free on $prefix"
fi

# Canonicalize sources. Directories (including symlinks to directories) are
# followed; other symlinks and files are stored as themselves.
source_paths=()
source_bases=()
for source in "${sources[@]}"; do
  [[ -n $source ]] || die "empty source path"
  while [[ $source != "/" && $source == */ ]]; do
    source=${source%/}
  done

  if [[ -d $source && ! -L $source ]]; then
    source_abs=$(cd -- "$source" 2>/dev/null && pwd -P) ||
      die "cannot access source directory: $source"
  else
    [[ -e $source || -L $source ]] || die "source does not exist: $source"
    source_parent_abs=$(cd -- "$(dirname -- "$source")" 2>/dev/null && pwd -P) ||
      die "cannot access source parent of: $source"
    source_abs=$source_parent_abs/$(basename -- "$source")
  fi

  base=${source_abs##*/}
  [[ -n $base && $base != "." && $base != ".." ]] ||
    die "cannot use filesystem root as a source"

  if [[ $source_abs == "$prefix" ||
        $source_abs == "$prefix/"* ||
        $prefix == "$source_abs/"* ]]; then
    die "source and snapshot directory must be disjoint: $source_abs and $prefix"
  fi

  for previous_base in "${source_bases[@]}"; do
    [[ $base != "$previous_base" ]] ||
      die "sources have the same basename '$base'; choose distinct source paths"
  done

  source_paths+=("$source_abs")
  source_bases+=("$base")
done

for pattern in "${excludes[@]}"; do
  [[ -n $pattern ]] || die "empty exclude pattern"
done

snapshot_path() { printf '%s/%s.%02d' "$prefix" "$name" "$1"; }

# Newest existing snapshot (tolerates gaps left by an interrupted rotation).
latest_snapshot() {
  local i p
  for ((i = 0; i < 100; i++)); do
    p=$(snapshot_path "$i")
    if [[ -d $p && ! -L $p ]]; then
      printf '%s' "$p"
      return 0
    fi
  done
  return 0
}

# Remove top-level entries in the stage that are no longer requested sources.
prune_stage() {
  local entry b found
  while IFS= read -r -d '' entry; do
    found=0
    for b in "${source_bases[@]}"; do
      if [[ $entry == "$b" ]]; then found=1; fi
    done
    if (( ! found )); then rm -rf -- "${stage:?}/$entry"; fi
  done < <(find "$stage" -mindepth 1 -maxdepth 1 -printf '%f\0')
}

stage=$prefix/.$name.inprogress
lock_file=$prefix/.$name.lock

cleanup() {
  local status=$?
  if (( status != 0 && staging )); then
    warn "backup did not complete (exit $status); partial data kept in $stage and reused next run"
  fi
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM

if (( ! dry_run )); then
  exec 9>"$lock_file" || die "cannot create lock file: $lock_file"
  flock -n 9 || die "another backup of '$name' is already running"

  [[ ! -L $stage ]] || die "refusing to use a symlink as staging directory: $stage"
  if [[ -d $stage ]]; then
    info "Resuming interrupted backup in $stage"
  elif [[ -e $stage ]]; then
    die "staging path exists and is not a directory: $stage"
  else
    mkdir -- "$stage"
  fi
  staging=1
  chown --reference="$prefix" -- "$stage"
  chmod --reference="$prefix" -- "$stage"
  prune_stage
fi

latest=$(latest_snapshot)

rsync_common=(-aHAX --numeric-ids)
if (( one_fs ));   then rsync_common+=(--one-file-system); fi
if (( checksum )); then rsync_common+=(--checksum); fi
if (( verbose )); then  rsync_common+=(--itemize-changes); fi
for pattern in "${excludes[@]}"; do
  rsync_common+=("--exclude=$pattern")
done

# 24 = files vanished during transfer (normal on a live system).
# 23 = some files could not be transferred: fatal unless --allow-partial.
run_rsync() {
  local rc=0
  rsync "$@" || rc=$?
  case $rc in
    0)  ;;
    24) warn "some source files vanished during transfer (ignored)" ;;
    23) if (( allow_partial )); then
          warn "some files could not be transferred (rsync exit 23); continuing (--allow-partial)"
        else
          die "rsync could not transfer some files (exit 23); fix permissions or use --allow-partial"
        fi ;;
    *)  die "rsync failed with exit code $rc" ;;
  esac
}

for i in "${!source_paths[@]}"; do
  src=${source_paths[$i]}
  base=${source_bases[$i]}
  rsync_args=("${rsync_common[@]}")

  if (( dry_run )); then
    if [[ -z $latest ]]; then
      info "Dry run: no previous snapshot exists; everything would be copied."
      break
    fi
    target=$latest
    rsync_args+=(--dry-run --itemize-changes)
  else
    target=$stage
  fi

  if [[ -d $src && ! -L $src ]]; then
    rsync_args+=(--delete --delete-excluded)
    if (( ! dry_run )); then
      mkdir -p -- "$target/$base"
      if [[ -n $latest && -d $latest/$base ]]; then
        rsync_args+=("--link-dest=$latest/$base")
      fi
    fi
    info "Synchronizing directory: $src"
    run_rsync "${rsync_args[@]}" -- "$src/" "$target/$base/"
  else
    if (( ! dry_run )) && [[ -n $latest ]]; then
      rsync_args+=("--link-dest=$latest")
    fi
    info "Synchronizing file or symlink: $src"
    run_rsync "${rsync_args[@]}" -- "$src" "$target/"
  fi
done

if (( dry_run )); then
  info "Dry run: nothing was changed."
  exit 0
fi

# Make the new data durable before deleting anything old.
sync -f -- "$stage" 2>/dev/null || sync
touch -- "$stage"   # snapshot directory mtime = completion time

# Rotate only after every rsync succeeded.
for ((i = 99; i >= keep; i--)); do
  old=$(snapshot_path "$i")
  if [[ -e $old || -L $old ]]; then rm -rf -- "$old"; fi
done

for ((i = keep - 1; i >= 1; i--)); do
  from=$(snapshot_path "$((i - 1))")
  to=$(snapshot_path "$i")
  if [[ -e $from || -L $from ]]; then
    if [[ -e $to || -L $to ]]; then rm -rf -- "$to"; fi
    mv -- "$from" "$to"
  fi
done

newest=$(snapshot_path 0)
if [[ -e $newest || -L $newest ]]; then rm -rf -- "$newest"; fi   # only if --keep 1
mv -- "$stage" "$newest"
staging=0

info "Backup complete: $newest"
