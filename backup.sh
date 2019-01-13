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

SVN="CV LaTeX Lectures Makefiles Research bin devel pub"
LINK="tools Official"
#MAIN="${SVN} ${LINK} Config WebPub bib man misc Library/Thunderbird/Profiles/56rgu1dz.default"
MAIN="${SVN} ${LINK} Config WebPub Desktop SVN.dump bib man misc .thunderbird"
CONF=".bashrc .bash_profile .bash_logout .emacs .profile .unison .my_dircolors .xmodmap_apple .signature_home .emacs_modes .ssh dorongnyong_ssh git"
#ALL="SVN ${MAIN} ${CONF}"
ALL="${MAIN} ${CONF}"

#prefix=/Volumes/Backup
prefix=/media/rinderkn/Backup
base=snapshot
new_snapshot="${prefix}/${base}.00"
#scripts=/Volumes/Users/rinderkn/devel/Scripts
scripts=/home/rinderkn/devel/Scripts

(cd ~
#$scripts/clean.sh --recursive ${SVN} ${LINK} public_html/CV public_html/Software
#$scripts/clean.sh public_html
$scripts/snapshot.sh -m "${ALL}" -p $prefix -f $base -u 99
printf "synchronising $new_snapshot with public_html..."
# Removed --perms --group --owner for exFAT
rsync --recursive --copy-links --times \
--exclude=.svn --ignore-errors \
--delete --delete-excluded --exclude=Lectures/ --exclude=Mirror/ \
public_html $new_snapshot
echo " done."
for path in LaTeX bin devel tools public_html/Software; do
  $scripts/symlinks.sh --set --recursive $path
done
$scripts/symlinks.sh --set public_html
$scripts/setup.sh public_html/CV
(cd public_html/CV; make; \
 chown rinderkn.rinderkn index_bib.html index.html)
)
#find bin -type l -exec chown -h rinderkn.rinderkn {} \;
