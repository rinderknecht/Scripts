#!/bin/sh
#
# pdf2jpg [input.pdf] [output.jpg]
#

if [ $# -lt 2 ]
then
    echo "Usage: pdf2jpg input.pdf output.pdf"
    exit 1
fi
convert -density 300 $1 -quality 100 $2
