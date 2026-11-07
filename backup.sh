#!/bin/sh

#set -x

HOME=/home/rinderkn
MAIN="Research bin git tools Official Pictures Turnstiles Private Desktop bib misc .thunderbird .opam"
CONF=".bash_history .bash_logout .bash_profile .bashrc .emacs .emacs_modes .gitconfig .profile .XCompose .config .ssh"

# Build one -m argument for each source.
set --
for item in $MAIN $CONF; do
    set -- "$@" -m "$HOME/$item"
done

# Checking that the external backup drive is mounted
prefix=/run/media/rinderkn/Backup
if ! mountpoint -q "$prefix"; then
    echo "ERROR: Backup drive is not mounted at $prefix" >&2
    exit 1
fi

# Checking that the external backup drive was formatted with ext4
fstype=$(findmnt -n -o FSTYPE --target "$prefix")

if [ "$fstype" != "ext4" ]; then
    echo "ERROR: Expected ext4 at $prefix, found '$fstype'" >&2
    exit 1
fi

base=snapshot
scripts=/home/rinderkn/git/Scripts

(cd "$HOME" || exit 1
 "$scripts/rotating-backup.sh" \
     "$@" \
     --prefix "$prefix" \
     --filename "$base" \
     --keep 60 \
     --require-mount "$prefix" \
     --min-free 10240)
