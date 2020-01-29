#!/bin/sh

# This script creates incremental and rotating backups using the
# method described by Mike Rubel at
# http://www.mikerubel.org/computers/rsync_snapshots/

# $Id: snapshot.sh 8433 2016-08-15 09:31:23Z rinderkn $

#set -x

# ====================================================================
# General Settings

quiet=no
debug=no

script=$(basename $0)

# ====================================================================
# Wrappers for several kind of displays
#
print_nl () { test "$quiet" != "yes" && echo "$1"; }

print () { test "$quiet" != "yes" && printf "$1";  }

fatal_error () {
  echo "$script: fatal error:"
  echo "$1" 1>&2
  exit 1
}

warn () {
 print_nl "$script: warning:"
 print_nl "$1"
}

debug_nl () { test "$debug" = "yes" && echo "$1"; }

# ====================================================================
# Parsing loop
#
while : ; do
  case "$1" in
    "") break;;
      # The directories that should be backed up.
      #
    -m)
      if test -n "$masters_opt"
      then fatal_error "Repeated option -m."
      fi
      masters=$2
      shift
      masters_opt="-m"
      ;;
    --masters=*)
      if test -n "$masters_opt"
      then fatal_error "Repeated option --masters."
      fi
      masters=$(expr "$1" : "[^=]*=\(.*\)")
      masters_opt="--masters"
      ;;
    --masters)
      long_short_opt=$1
      break
      ;;
      # The directory where snapshots should be stored.
      #
    -p)
      if test -n "$prefix_opt"
      then fatal_error "Repeated option -p."
      fi
      prefix=$2
      shift
      prefix_opt="-p"
      ;;
    --prefix=*)
      if test -n "$prefix_opt"
      then fatal_error "Repeated option --prefix."
      fi
      prefix=$(expr "$1" : "[^=]*=\(.*\)")
      prefix_opt="--prefix"
      ;;
    --prefix)
      long_short_opt=$1
      break
      ;;
      # The file name, without extension, used to form the
      # name of every snapshot.
      #
    -f)
      if test -n "$filename_opt"
      then fatal_error "Repeated option -f."
      fi
      filename=$2
      shift
      filename_opt="-f"
      ;;
    --filename=*)
      if test -n "$filename_opt"
      then fatal_error "Repeated option --filename."
      fi
      filename=$(expr "$1" : "[^=]*=\(.*\)")
      filename_opt="--filename"
      ;;
    --filename)
      long_short_opt=$1
      break
      ;;
      # The number $up_to is the number of snapshots that should be
      # kept minus one (because snapshots are numbered from 0).
      #
    -u)
      if test -n "$up_to_opt"
      then fatal_error "Repeated option -u."
      fi
      if test -z "$2"
      then fatal_error "Argument of option -u is missing."
      fi
      up_to=$2
      shift
      up_to_opt="-u"
      ;;
    --up-to=*)
      if test -n "$up_to_opt"
      then fatal_error "Repeated option --up-to."
      fi
      up_to=$(expr "$1" : "[^=]*=\(.*\)")
      up_to_opt="--up-to"
      ;;
    --up-to)
      long_short_opt=$1
      break
      ;;
      # Files that should be excluded from the backup process,
      # specified using rsync's --exclude syntax. Prefix $masters
      # must be removed. In case of directories, add a trailing /
      # after the name.
      #
    -x)
      if test -n "$exclude_opt"
      then fatal_error "Repeated option -x."
      fi
      if test -z "$2"
      then fatal_error "Argument of option -x is missing."
      fi
      exclude=$2
      shift
      exclude_opt="-x"
      ;;
    --exclude=*)
      if test -n "$exclude_opt"
      then fatal_error "Repeated option --exclude."
      fi
      exclude=$(expr "$1" : "[^=]*=\(.*\)")
      exclude_opt="--exclude"
      ;;
    --exclude)
      long_short_opt=$1
      break
      ;;
      # Display debug information
      #
    -d | --debug)
      debug=yes
      debug_opt=$1
      ;;
      # A toggle which causes this script to say what it would do,
      # without doing it.
      #
    -n | --just-print)
      if test -n "$just_print_opt"
      then fatal_error "Repeated option $1."
      fi
      just_print=yes
      just_print_opt=$1
      ;;
      # Help
      #
    -h | --help | -help)
      help=yes
      help_opt=$1
      ;;
      # Version
      #
    -v | --version | -version)
      version=yes
      version_opt=$1
      ;;
      # Quiet
      #
    -q | --quiet)
      quiet=yes
      quiet_opt=$1
      ;;
      # Invalid option
      #
    -*)
      fatal_error "Invalid option \"$1\"."
      ;;
      # Invalid argument
      #
     *)
      fatal_error "Invalid argument \"$1\"."
  esac
  shift
done

# ====================================================================
# Help
#
usage () {
  cat <<EOF
Usage: $(basename $0) [-hvnqd][-x <paths>][-u <num>]
                      -m <paths> -p <path> -f <filename>
Creates incremental and rotating backups using rsync.
Method by Mike Rubel described at
http://www.mikerubel.org/computers/rsync_snapshots/

The following options, if given, must be given only once.

Display control:
  -h, --help           display this help and exit
  -v, --version        display version information and exit
  -n, --just-print     just print the commands and exit
  -q, --quiet          do not print any kind of message
  -d, --debug          display debug information (even if -q)

Mandatory options:
  -m, --masters=PATHS  directories and files to be backed up
                       (directories with no trailing slash)
  -p, --prefix=DIR     directory where to put the snapshot
                       (without trailing slash)
  -f, --filename=NAME  name of the snapshot
                       (without dot and extension)

  The most recent snapshot of PATHS is DIR/NAME.00
  DIR and PATHS must be disjoint trees.

Additional options:
  -x, --exclude=PATHS  directories and files to be excluded
                       from the snapshot (directories with
                       trailing slash) of a unique master
                       directory (see --masters); paths are
                       relative to the master directory

  -u, --up-to=NUM      maximum number of snapshots, lower
                       than 100; default is 31; overflowing
                       snapshots are deleted
EOF
  exit 1
}

if test "$help" = "yes"; then usage; fi

# ====================================================================
# Checking the command-line options and arguments and applying some of
# them.

# It is a common mistake to forget the "=" in GNU long-option style.
#
if test -n "$long_short_opt"
then
  fatal_error "Long option style $long_short_opt must be followed by \"=\"."
fi

# Next, let us give priority to the query of the current version of
# this script.
#
if test "$version" = "yes"
then echo "$(basename $0) version 0.1"
     exit 1
fi

# At least one master directory or file is mandatory.
# No trailing slash is allowed for the master directories.
# All master directories or file must exist.
#
if test -z "$masters"
then fatal_error "No masters to backup (use --masters)."
fi
master_dirs=
for master in $masters; do
  trailing_slash=$(expr "$master" : ".*/$")
  if test -d $master
  then
    if test "$trailing_slash" != "0"
    then fatal_error "Trailing slash for master \"$master\" (check $masters_opt)."
    fi
    if test -z "$master_dirs"
    then master_dirs=$master
    else master_dirs="$master_dirs $master"
    fi
  elif test ! -e $master
    then fatal_error "Missing master \"$master\" (check $masters_opt)."
  fi
done

debug_nl "masters directories and files.... $masters"
debug_nl "masters directories.............. $master_dirs"

# A prefix path for the snapshots
#  1) is mandatory,
#  2) must refer to an existing directory,
#  3) must not be terminated by a slash.
#
if test -z "$prefix"
then fatal_error "No snapshot path (use --prefix)."
elif test ! -d "$prefix"
  then fatal_error "Snapshot directory \"$prefix\" not found (check $prefix_opt)."
else
  trailing_slash=$(expr "$prefix" : ".*/$")
  if test "$trailing_slash" != "0"
  then fatal_error "Trailing slash for prefix path \"$prefix\" (check $prefix_opt)."
  fi
fi

debug_nl "snapshots prefix................. $prefix"

# A name (without extension) for the snapshots is compulsory.
#
if test -z "$filename"
then fatal_error "No snapshot filename (use --filename)."
fi

debug_nl "snapshot filename................ $filename"

# The maximum number of snapshots is by default 31, hence the option
# is not mandatory. If present, this number must range from 1 to 99,
# bounds included.
#
if test -n "$up_to"
then
  numeric=$(expr $up_to : "([0-9]+)")
  if test -z "$numeric"
  then fatal_error "Non numeric argument ($up_to) to option $up_to_opt."
  fi
  if test $up_to -lt 0
  then fatal_error "Negative number of snapshots (check $up_to_opt)."
  fi
  if test $up_to -eq 0
  then fatal_error "Zero snapshot required (check $up_to_opt)."
  fi
  if test $up_to -gt 99
  then fatal_error "Maximum number of snapshots greater than 99 (check $up_to_opt)."
  fi
else up_to=31
fi
max_digits=${#up_to}

debug_nl "maximum number of snapshots...... $up_to"

if test -n "$exclude_opt"
then
  # Since there is an exclusion list, there must be at most one master
  # directory to back up (because, otherwise, we would not know to which
  # master directory apply the exclusion list).
  #
  num_master_dirs=$(echo $master_dirs | wc -w)
  if test "$num_master_dirs" != "1"
  then fatal_error "Several master directories with exlusions (check $masters_opt and $exclude_opt)."
  fi


  # Check for absolute paths (only existing paths relative to the
  # master directory are valid)
  #
  for excluded in $exclude; do
    starting_slash=$(expr "$excluded" : "/")
    if test "$starting_slash" = "1"
    then fatal_error "Absolute excluded path \"$excluded\" (check $exclude_opt)."
    fi
  done

  # Warn if an excluded path does not exist.
  #
  for excluded in $exclude; do
    if test ! -e $master_dirs/$excluded
    then warn "Excluded path \"$master_dirs/$excluded\" is missing (check $exclude_opt)."
    fi
  done

  # Check for missing trailing slashes on existing excluded
  # directories (they indeed must be followed by a slash).
  #
  for excluded in $exclude; do
    trailing_slash=$(expr "$excluded" : ".*/$")
    if test "$trailing_slash" = "0" -a -d $master_dirs/$excluded
    then fatal_error "No trailing slash for excluded directory \"$excluded\" (check $exclude_opt)."
    fi
  done

  debug_nl "excluded directories and files... $exclude"

  # Building the options for [rsync]
  #
  for excluded in $exclude; do
    if test -n "$exclusion"
    then exclusion="$exclusion --exclude=$excluded"
    else exclusion="--exclude=$excluded"
    fi
  done
fi

#====================================================================
# Snapshot names
#
# Snapshot's indexes span from 00 to 99, included. Make sure the
# arguments to the following functions are two-digits numbers!
#

snapshot () {
  echo $prefix/$filename.$1
}

snapshot_log () {
  echo $(snapshot $1).log
}

snapshot_err () {
  echo $(snapshot $1).err
}

# ====================================================================
# Command wrappers
#
# Generic wrapping around shell commands in order to handle nicely
# standard error output and fatal errors.
#
command () {
  if test "$just_print" = "yes"
  then print_nl "$1"
  else if test -n "$2"
       then print "$2... "
       fi
       err_msg=$(eval "$1" > /dev/null 2>&1)
       if test -n "$err_msg"
       then print_nl "FAILED:"
            print_nl "$err_msg"
            fatal_error "$1"
       elif test -n "$2"
         then print_nl "done."
       fi
  fi
}

wrap_touch () {
  if test -n "$2"
  then local msg=""
  else local msg="touching $1"
  fi
  command "touch $1" "$msg"
}

wrap_rm () {
  if test -e "$1"
  then if test -n "$2"
       then local msg=""
       else local msg="removing $1"
       fi
       command "rm -fr $1" "$msg"
  fi
}

wrap_mv () {
  if test -e "$1"
  then if test -n "$3"
    then local msg=""
    else local msg="moving $1 to $2"
    fi
    command "mv $1 $2" "$msg"
  fi
}

# Removed --perms --group --owner for exFAT

wrap_rsync () {
  if test -n "$2"
  then if test -e "$1"
       then if test -n "$3"
            then local msg=""
            else local msg="synchronising $(snapshot $2) with $1"
            fi
            command \
"rsync -rLt --exclude=.svn --ignore-errors --delete --delete-excluded $exclusion $1 $(snapshot $2) > $(snapshot_log $2)" "$msg"
       fi
  fi
}

# ====================================================================
# Main

if test "$just_print" = "yes"
then print_nl "Statically scheduled commands:"
fi

# Determine all the current snapshots and their highest index.
#
max_index=0
indexes=
for snap in $(ls $prefix | grep "$filename\.[[:digit:]]\+" | tr '\n' ' '); do
  index=$(expr "$snap" : "$filename\.\([[:digit:]]*\)")
  if test "$index" -gt "$max_index"
  then max_index=$index
  fi
  indexes="$index $indexes"
done

indexes=$(echo $indexes | tr -s ' ')

debug_nl "current snapshot indexes......... [$indexes]"

# Function "rm_snapshot" removes the snapshot $1 as well as the
# possible associated log and error file (always silently).
#
rm_snapshot () {
  wrap_rm $(snapshot $1) $2
  wrap_rm $(snapshot_log $1) "silent"
  wrap_rm $(snapshot_err $1) "silent"
}

# Delete the snapshots with higher indexes which overflow the maximum
# number of snapshots $up_to - 1 (one is to make room for the
# rotation).
#
current_number_of_snapshots=$(echo $indexes | wc -w | tr -d ' ')

#echo "current_number_of_snapshots=[$current_number_of_snapshots]"
#echo "up_to=[$up_to]"

if test $current_number_of_snapshots -ge $up_to
then removed_num=$(expr $current_number_of_snapshots - $up_to + 1)
     debug_nl "snapshots to be removed.......... $removed_num"
     remaining_indexes=
     for index in $indexes; do
       if test "$removed_num" = "0"
       then remaining_indexes="$remaining_indexes $index"
       else rm_snapshot $index
            removed_num=$(expr $removed_num - 1)
       fi
     done
else remaining_indexes="$indexes"
fi

debug_nl "remaining indexes................ [$remaining_indexes]"

# Shift up (i.e. increment) the index of all intermediate snapshots,
# i.e. indexes down until 01, included.
#
proper_indexes=$(expr "$remaining_indexes" : "\(.*\) 00")
debug_nl "proper indexes................... [$proper_indexes]"

shift_snapshot () {
  cur_digits=${#1}
  next=$(expr $1 + 1)
  next_digits=${#next}
  padding=$(expr $cur_digits - $next_digits)
  if test "$padding" -gt 0
  then n=$padding
       while test $n -gt 0; do next=0$next; n=$(($n-1)); done
  fi
  wrap_mv $(snapshot $1) $(snapshot $next) $2
  wrap_mv $(snapshot_log $1) $(snapshot_log $next) "silent"
  wrap_mv $(snapshot_err $1) $(snapshot_err $next) "silent"
}

for n in $proper_indexes; do shift_snapshot $n; done

# Make a hard-link-only copy of the newest snapshot. After this
# step, the snapshots 00 and 01 are trees with separate
# infrastructures, but shared leaves.
#
hard_copy () {
  if test -e "$1" -a -n "$2"
  then if test -n "$3"
       then local msg=""
       else local msg="hard-copying $1 to $2"
       fi
       command "(cd $1; find . -depth -print0 | cpio -paml0d --quiet $2)" "$msg"
  fi
}

hard_copy $(snapshot 00) $(snapshot 01)

# Accordingly, we make sure to shift the log and the possible error
# file from index 00 to 01.
#
wrap_mv $(snapshot_log 00) $(snapshot_log 01) "silent"
wrap_mv $(snapshot_err 00) $(snapshot_err 01) "silent"

# Now, create a fresh snapshot of the master directories. This is done
# using rsync, which copies a file only if it has changed, so only
# files which have actually changed will be un-shared with snapshot
# 01. This works because [rsync] removes the destination file before
# copying, so if the destination file was shared with other snapshots,
# these are not affected.
#
for master in $masters; do wrap_rsync $master 00; done

# Update the modification time of the latest snapshot.
#
wrap_touch $(snapshot 00)
wrap_touch $(snapshot_log 00) "silent"
wrap_touch $(snapshot_err 00) "silent"

# Remove the empty logs
#
for err in $(find $prefix -maxdepth 1 -name "$filename.??.err" -empty); do
  wrap_rm $err "silent"
done

for log in $(find $prefix -maxdepth 1 -name "$filename.??.log" -empty); do
  wrap_rm $log "silent"
done
