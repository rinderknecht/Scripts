#!/bin/sh

# lf2crlf
# adds an extra carriage return in a Unix
# text file so that end of line matches
# the Windows/DOS convention

usage() {
 echo "usage: lf2crlf unix.txt dos.txt"
 exit
}

test $# != 2 && usage

sed 's/$//g' <$1 >$2
