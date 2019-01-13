#!/bin/sh

# Easier procedure:
#
#  texlua install-getnonfreefonts
#  getnonfreefonts-sys luximono
#  updmap --enable Map=ul9.map

set -x

FONTS=$HOME/LaTeX/Fonts/LuxiMono
TEXMF=/usr/share/texmf-texlive

mkdir -p $TEXMF/fonts/type1/public/luxi
cp $FONTS/*.pfb $TEXMF/fonts/type1/public/luxi

mkdir -p $TEXMF/fonts/afm/public/luxi
cp $FONTS/*.afm $TEXMF/fonts/afm/public/luxi

unzip $FONTS/ul9.zip -d $TEXMF

mkdir -p $TEXMF/fonts/map/dvips/ul9
mv $TEXMF/dvips/config/ul9.map $TEXMF/fonts/map/dvips/ul9

#updmap-sys
#mktexlsr

updmap --enable Map=ul9.map

updmap-sys
mktexlsr

