#!/bin/sh

#set -x

MAIN="Research bin git tools Official Pictures Turnstiles Private Desktop bib misc .thunderbird .opam"
CONF=".bash_history .bash_logout .bash_profile .bashrc .emacs .emacs_modes .gitconfig .profile .XCompose .config .xmodmap_apple .ssh"
ALL="${MAIN} ${CONF}"

prefix=/media/rinderkn/Backup
base=snapshot
new_snapshot="${prefix}/${base}.00"
scripts=/home/rinderkn/git/Scripts

(cd ~
$scripts/snapshot.sh -m "${ALL}" -p $prefix -f $base -u 60
printf "synchronising $new_snapshot with public_html..."
echo " done.")
