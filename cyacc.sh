#!/bin/sh

if test $# = 1
then
  base=$(basename $1 .mly)
  menhir --only-preprocess --infer $1 >| $base.pp.mly
  sed 's|\([[:alpha:]][[:alnum:]]* = \)||g' $base.pp.mly >| $base.ppp.mly
  ocamlyacc -v $base.ppp.mly
fi
