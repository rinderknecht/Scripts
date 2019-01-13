#!/bin/sh

# crlf2lf
# removes an extra carriage return in a DOS/Windows
# text file so that end of line matches
# the Unix convention.
# Also removes a control-Z at end of file.

usage() {
 echo "usage: crlf2lf dos.txt unix.txt
 exit
}

test $# != 2 && usage

sed 's///g
s///g' <$1 >$2
