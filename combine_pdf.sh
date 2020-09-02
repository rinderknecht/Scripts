#!/bin/sh

# set -x

if [ $# -lt 2 ]
then
    echo "Usage: combine_pdf.sh output.pdf input1.pdf input2.pdf ..."
    exit 1
fi

target="$1"
shift
gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=$target -dBATCH "$@"
