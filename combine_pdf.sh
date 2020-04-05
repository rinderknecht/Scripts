#!/bin/sh

# set -x

target="$1"
shift
gs -dNOPAUSE -sDEVICE=pdfwrite -sOUTPUTFILE=$target -dBATCH "$@"
