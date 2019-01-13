#!/bin/sh

#set -x

if test -n "$1"
then
    ext_mod=$(sed -n "s/^\(.*\): $1/\1/p" .ext | sort -u)
else
    ext_mod=$(sed "s/^\(.*\):.*/\1/g" .ext | sort -u)
fi

libs=
packs=

for Ext in $ext_mod; do
  ext=$(echo $Ext | sed "s/\<./\l&/g")
  lib=$(ocamlfind printconf path \
        | xargs -n1 -I/ find / -name $ext.cmi -or -name $Ext.cmi)
  pack=$(dirname $lib | sed "s|.*/\(.*\)|\1|g")

  if test "$pack" != "ocaml" -a -n "$lib"
  then libs="$libs $(basename $lib .cmi)"
       packs="$packs $pack"
  fi
done

echo $libs
echo $packs
