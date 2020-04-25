#!/bin/sh
#

if [ $# -lt 3 ]
then
  echo "Usage: unlock_pdf.sh password locked.pdf unlocked.pdf"
  exit 1
fi

gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -SPDFPassword=$1 -sOutputFile=$3 -c .setpdfwrite -f $2
