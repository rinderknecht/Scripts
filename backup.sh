#!/bin/sh

#set -x

CODE="Research bin git tools"
DOCS="Official Pictures Turnstiles NOTES Personnel"
MAIN="${CODE} ${DOCS} Desktop bib misc .thunderbird .opam .nvm"
CONF=".aspell.en.prepl .aspell.en.pws .bash_history .bash_logout .bash_profile .bashrc .emacs .emacs_modes .gitconfig .profile .my_dircolors .XCompose .Xdefaults .xdvirc .xinputrc .xsession .Xsession .config .xmodmap_apple .ssh .dbus .dmrc"
ALL="${MAIN} ${CONF}"

prefix=/media/rinderkn/Backup
base=snapshot
new_snapshot="${prefix}/${base}.00"
scripts=/home/rinderkn/git/Scripts

(cd ~
$scripts/snapshot.sh -m "${ALL}" -p $prefix -f $base -u 60
printf "synchronising $new_snapshot with public_html..."
echo " done.")
