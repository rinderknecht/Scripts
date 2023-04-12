#!/bin/sh

for html in $(ls *.html); do
  xml=$(basename $html .html).xml
  echo '<?xml version="1.0" encoding="iso-latin-1"?>' >| $xml
  echo >> $xml
  sed -e 's|<head>||g;s|</head>||g;s|<body>||g;s|</body>||g;s|<hr>||g' \
      -e 's|<h1>.*</h1>||g' \
      -e 's|<title>\(.*\)</title>|<book title="\1">|g' \
      -e "s|<FONT COLOR=red>||g;s|<FONT COLOR=RED>||g" \
      -e "s|</FONT>||g" \
      -e 's|<h2><A NAME="[0-9]\+">[A-Za-z]\+[ ]\+\([0-9]\+\)</A></h2>|<chapter num="\1">|g' \
      -e 's|<dl compact>||g' \
      -e 's|</dl compact>|</chapter>|g' \
      -e 's|<dt><A NAME="[0-9]\+\.\([0-9]\+\)">[ ]*[0-9]\+\.[0-9]\+</A><dd>\(.*\)|  <verse num="\1">\2</verse>|g' $html >> $xml
  echo '</book>' >> $xml
done

