#!/bin/sh
#
# jpg2pdf [input.jpg] [output.pdf]
#

if [ $# -lt 2 ]
then
    echo "Usage: jpg2pdf input.jpg output.pdf"
    exit 1
fi
convert -density 300 $1 -quality 100 $2
