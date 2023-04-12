#!/bin/sh

#set -x

# Script parameters:
#   ${1} should be ${DOC} in Makefile.cfg,

doc=${1}

#parts=$(ls *.pp 2> /dev/null)

#if test -n "$parts"
if test -e "$doc.pp"
then
#  for pp in $parts; do
#    doc=$(basename $pp .pp)
      (cat $doc.pp \
    | while read line; do
        page_range=$(echo $line | sed -n -E 's|([0-9]*-[0-9]*):.*|\1|p')
        filename=$(echo $line | sed -n -E 's|.*:(.*):.*|\1|p')
        if test -e "$filename.ps"
        then
#          printf "Deleting $filename.ps..."
          rm -f $filename.ps
#           echo " done."
        fi
        if test -e "$filename.pdf"
        then
#          printf "Deleting $filename.pdf..."
          rm -f $filename.pdf
#          echo " done."
        fi
        if test -e "$doc--$page_range.ps"
        then
#          printf "Deleting $doc--$page_range.ps..."
          rm -f $doc--$page_range.ps
#          echo " done."
        fi
        if test -e "$doc--$page_range.pdf"
        then
#          printf "Deleting $doc--$page_range.pdf..."
          rm -f $doc--$page_range.pdf
#          echo " done."
        fi
      done)
#    printf "Deleting $pp..."
#    rm -f $pp
#    printf "Deleting $doc.pp..."
    rm -f $doc.pp
#    echo " done."
#  done
fi

#html_files=$(ls *.phtml 2> /dev/null)

#if test -n "$html_files"
if test -e "$doc.phtml"
then
#  printf "Deleting $doc.phtml..."
  rm -f $doc.phtml
#  echo " done."
#  printf "Deleting *.phtml..."
#  for html_file in $html_files; do
#    rm -f $html_file
#  done
#  echo " done."
fi

if test -e all_slides
then
  rm -f all_slides
fi

titles=$(ls .*.title 2> /dev/null)

if test -n "$titles"
then
#  printf "Deleting .*.title..."
  for title in $titles; do rm -f $title; done
#  echo " done."
fi

languages=$(ls .*.lang 2> /dev/null)

if test -n "$languages"
then
#  printf "Deleting .*.lang..."
  for language in $languages; do rm -f $language; done
#  echo " done."
fi

dates=$(ls .*.date 2> /dev/null)

if test -n "$dates"
then
#  printf "Deleting .*.date..."
  for time_stamp in $dates; do rm -f $time_stamp; done
#  echo " done."
fi
