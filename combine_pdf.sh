#!/bin/sh

gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=$1.pdf -dBATCH "${@:2}"
