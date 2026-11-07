#!/bin/sh

# IMPORTANT: Run once in a while the following command:
# $ verify-backup.sh --checksum

HOME=/home/rinderkn
MAIN="Research bin git tools Official Pictures Turnstiles Private Desktop bib misc .thunderbird .opam"
CONF=".bash_history .bash_logout .bash_profile .bashrc .emacs .emacs_modes .gitconfig .profile .XCompose .config .ssh"

prefix=/run/media/rinderkn/Backup
snap=$prefix/snapshot.00

# Pass --checksum as the first argument for a content comparison (slow).
extra=$1

mountpoint -q "$prefix" || { echo "ERROR: $prefix not mounted" >&2; exit 1; }
[ -d "$snap" ] || { echo "ERROR: no $snap" >&2; exit 1; }

status=0
for item in $MAIN $CONF; do
    src=$HOME/$item
    if [ ! -e "$src" ] && [ ! -L "$src" ]; then
        echo "MISSING SOURCE: $src"
        continue
    fi
    if [ -L "$src" ]; then
        out=$(rsync -aHAXn --numeric-ids -i $extra "$src" "$snap/" 2>&1)
    elif [ -d "$src" ]; then
        out=$(rsync -aHAXn --numeric-ids --delete -i $extra \
              "$src/" "$snap/$item/" 2>&1)
    else
        out=$(rsync -aHAXn --numeric-ids -i $extra "$src" "$snap/" 2>&1)
    fi
    # Directory timestamp-only changes are harmless noise.
    out=$(printf '%s\n' "$out" | grep -v '^\.d\.\.t\.\.\.\.\.\. ')
    if [ -n "$out" ]; then
        status=1
        echo "=== $item"
        printf '%s\n' "$out"
    fi
done

[ $status -eq 0 ] && echo "All checked items match snapshot.00."
exit $status
