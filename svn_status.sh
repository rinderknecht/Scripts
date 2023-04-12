#!/bin/sh

#set -x

svn_dirs=$(find $1 -maxdepth 2 -name .svn -type d)

for svn_dir in $svn_dirs; do
  versioned_dir=$(dirname $svn_dir)
  if test "$versioned_dir" != "." -a "$versioned_dir" != "./public_html"
  then
    (cd $versioned_dir
    echo "Checking directory $(pwd)..."
    clean.sh --quiet --recursive
    svn status --show-updates)
  fi
done

~/devel/Scripts/symlinks.sh -r -s ~/LaTeX
~/devel/Scripts/symlinks.sh -r -s ~/devel/Scripts
