#!/bin/sh

# On Mac OS X, requires environment variable set as follows:
#  export TMPDIR=.

bibtex2html -o index -s not_so_plain -d -r -t "<h2>Publications by Christian Rinderknecht<h2>" -nf ps PostScript -nf pdf PDF cv_academy.bib
