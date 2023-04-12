#!/bin/sh

# This script patches the LaTeX template files to make an examination answer.

# set -x

if test -L ${1}.tex
then
  base=$(basename ${1} -QA)
  echo -n "Replacing ${1}.tex with a patched $base.tex..."
  perl -pi -e 's|(\\input{question\_([0-9]*)})|\1\n\\input{answer\_\2}|g' ${1}.tex
  echo " done."
else
  echo "warning: ${1}.tex should be a symbolic link."
fi
