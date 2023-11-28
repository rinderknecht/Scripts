#!/bin/sh

# For OS X:
# sudo mount -t hfsplus -o force,rw /dev/sdb2 /media/rinderkn/Backup
#
# For some reason, remounting the filesystem does not work:
# sudo mount -t hfsplus -o remount,force,rw /dev/sdb2
#
# To force a check on the HFS+ partition:
# sudo umount /dev/sdb2
# sudo fsck.hfsplus -fy /dev/sdb2

#set -x

CODE="Research bin pub git tools LaTeX Personnel Makefiles public_html"
DOCS="Official LIGO_lang Pictures Turnstiles"
MAIN="${CODE} ${DOCS} Desktop SVN.dump bib misc .thunderbird .opam .nvm"
CONF=".aspell.en.prepl .aspell.en.pws .bash_history .bash_logout .bash_profile .bashrc .emacs .emacs_modes .gitconfig .profile .my_dircolors .XCompose .Xdefaults .xdvirc .xinputrc .xsession .Xsession .config .xmodmap_apple .ssh .dbus .dmrc gitlab-recovery-codes.txt"
ALL="${MAIN} ${CONF}"

#prefix=/Volumes/Backup
prefix=/media/rinderkn/Backup
base=snapshot
new_snapshot="${prefix}/${base}.00"
scripts=/home/rinderkn/git/Scripts

(cd ~
$scripts/snapshot.sh -m "${ALL}" -p $prefix -f $base -u 99
printf "synchronising $new_snapshot with public_html..."
# Removed --perms --group --owner for exFAT
# rsync --recursive --copy-links --times \
# --exclude=.svn --ignore-errors \
# --delete --delete-excluded --exclude=Lectures/ \
# public_html $new_snapshot
echo " done."
#for path in bin tools; do
#  $scripts/symlinks.sh --set --recursive $path
#done
#$scripts/symlinks.sh --set public_html
#$scripts/setup.sh public_html/CV
#(cd public_html/CV; make; \
# chown rinderkn.rinderkn index_bib.html index.html)
)
#find bin -type l -exec chown -h rinderkn.rinderkn {} \;
