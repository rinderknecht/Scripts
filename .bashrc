# BASH initialisations
# (c) Christian Rinderknecht, 2006--2025

# Bash knows different kinds of shells:
#
#  1. Interactive shells
#     They are of two kinds:
#       1.1 Login shells,
#       1.2 Non-login shells.
#  2. Non-interactive shells.
#
# INTERACTIVE LOGIN SHELLS
# (or non-interactive shells with the `--login' option)
#
# They first source
#   1.1.1 /etc/profile
# Then they look in turn for
#   1.1.2 ~/.bash_profile,
#   1.1.3 ~/.bash_login,
#   1.1.4 ~/.profile
# and execute only the first readable of these files.
# Upon exiting a login shell, ~/.bash_logout is sourced.
#
# INTERACTIVE NON-LOGIN SHELLS
#
# They source ~/.bashrc.
#
# To enable bash completion in interactive shells, uncomment the
# following:
#
# if ! shopt -oq posix; then
#  if [ -f /usr/share/bash-completion/bash_completion ]; then
#    . /usr/share/bash-completion/bash_completion
#  elif [ -f /etc/bash_completion ]; then
#    . /etc/bash_completion
#  fi
# fi
#
# in /etc/bash.bashrc. In particular, this enables autocompletion on
# package names with [sudo apt-get install ...]
#
# NON-INTERACTIVE SHELLS
#
# They are started to run scripts. They source $BASH_ENV if its
# expansion is not the empty string.
#
# OUR POLICY
#
# We put every initialisation in ~/.bashrc and source it from
# ~/.bash_profile. This way, all interactive shells will use the same
# settings.

#=====================================================================
# Debugging

# set -x

# If the current shell is interactive, echo a trace.
#
# case "$-" in
#  *i*) echo "Sourcing $HOME/.bashrc...";;
# esac

# if test -r /etc/profile;
# then
#   source /etc/profile
# fi

#=====================================================================
# General settings

#---------------------------------------------------------------------
# X11 server
#
export DISPLAY=:0.0

#---------------------------------------------------------------------
# Kill CAPS lock
#
setxkbmap -option caps:none

#---------------------------------------------------------------------
# Remapping the Apple Wireless keyboard with X11
#
xmodmap ~/.xmodmap_apple 2>/dev/null

#---------------------------------------------------------------------
# Bristish English as language locale
#
export LC_CTYPE=en_GB.UTF-8
export LANG=en_GB.UTF-8
export LC_TIME=en_GB.UTF-8

#---------------------------------------------------------------------
# Paths (see the end of this file for final export of PATH)
#
# From highest to lowest priority:
#  1. User's binaries and scripts:
#       $HOME/bin
#  2. User tools
#       $HOME/tools/<name>
#       $HOME/tools/<name>/bin
#  3. Binaries installed locally
#       /usr/local/sbin
#       /usr/local/bin
#  4. Binaries installed user-wide
#       /usr/sbin
#       /usr/bin
#       /usr/X11R6/bin
#       /usr/games
#  5. Binaries installed system-wide
#       /sbin
#       /bin
#
HOME_BIN=$HOME/bin:$HOME/git/Scripts:$HOME/.nitrile/bin:$HOME/node_modules/.bin
USR_LOCAL_BIN=/usr/local/sbin:/usr/local/bin
REL_BIN=:.nvm/versions/node/v20.8.0/bin/:.cargo/bin
SYS_BIN=/sbin:/bin
SNAP_BIN=/snap/bin
export PATH=$HOME_BIN:$REL_BIN:$USR_LOCAL_BIN:$SYS_BIN:$SNAP_BIN
#:$NIX_PATH

LD_LIBRARY_PATH=/usr/local/lib

#---------------------------------------------------------------------
# Manuals and info files
#
# In the same order as the binary paths.
#
MAN=$HOME/man:$HOME/share/man:/usr/local/man:/usr/local/share/man:/usr/share/man
export INFOPATH=.:$HOME/info:/usr/local/info:/usr/local/share/info:/usr/share/info
export MANPATH=$MANPATH:$MAN

#---------------------------------------------------------------------
# Public access rights as a default
#
umask 022

#---------------------------------------------------------------------
# No core files by default and unlimited RAM and 2048 file handlers
#
ulimit -S -c 0 > /dev/null 2>&1
ulimit -f unlimited # 2000000
ulimit -n 2048

#---------------------------------------------------------------------
# No Num Lock
#
#[ ! -z "$DISPLAY" ] && numlockx off

#---------------------------------------------------------------------
# After any history actions, place the resulting line to the command
# prompt for review:
#
shopt -s histverify

#---------------------------------------------------------------------
# Terminal settings
#
#
# We want `ls' to use more colours (e.g., to show broken links)
# Sourcing the ouput of `dircolors' sets the environment variable
# LS_COLORS, which is read by `ls' for formatting the display.
#
# if test ! -s ~/.my_dircolors -a -n "`type -P dircolors`"
# then
#   dircolors --bourne-shell --print-database >| ~/.my_dircolors
#   source ~/.my_dircolors
# fi
#
export CLICOLOR=true
export LS_OPTIONS='--color=auto'
export LSCOLORS='Bxgxfxfxcxdxdxhbadbxbx'

#---------------------------------------------------------------------
# Prompts
#
USER=$(whoami)

if test "$USER" = "root"
then
  export PS2="#"
  export PS1='\[\033]0;\u@\h:\w\007\]# '
else
  export PS2="$"
  export PS1='\[\033]0;\u@\h:\w\007\]$ '
fi

#---------------------------------------------------------------------
# Aliases

shopt -s expand_aliases

#---------------------------------------------------------------------
# Aliases
#
alias rm='\rm -i'
alias cp='\cp -i'
alias mv='\mv -i'
alias ls='\ls --color=auto'
#alias xdvi='xdvi $1 > /dev/null 2>&1'
#alias fr="setxkbmap -layout 'fr' -variant 'oss' -option ''"
#alias us="setxkbmap -layout 'us' -variant '' -option ''"

alias xquery='java -cp ~/bin/saxon.jar net.sf.saxon.Query'
alias xslt='java -jar ~/bin/saxon.jar'
alias discord='discord > /dev/null 2>&1'
alias my_ip='curl https://ipinfo.io/ip'

#=====================================================================
# Applications

#---------------------------------------------------------------------
# Emacs
#
export EDITOR=emacs
EMACS_LIB=$HOME/lib/emacs
HOME_LIB=$EMACS_LIB

#---------------------------------------------------------------------
# Erlang
#
export ERLC=erlc

#---------------------------------------------------------------------
# Prolog
#
export SWIPL=swipl

#---------------------------------------------------------------------
# Java
#
# To select a given version:
# $ sudo update-alternatives --config java
#
export CLASSPATH=.
export JAVA_HOME=$(readlink -f /usr/bin/java | sed "s:bin/java::")
export JAVA=$(which java)
export JAVAC=$(which javac)

#---------------------------------------------------------------------
# Saxon (XSLT/XQuery/XPath)
#
export SAXON=$HOME/bin/saxon.jar

#---------------------------------------------------------------------
# Xmllint
#
export XMLLINT=$(which xmllint)

#---------------------------------------------------------------------
# LaTeX/TeX (TeX Live distribution)
#
export TEXINPUTS=.::  # The empty string is necessary for TEXINPUTS

#---------------------------------------------------------------------
# XCompose (accents and symbols)
#
setxkbmap -option "compose:caps"

#---------------------------------------------------------------------
# NVM
#
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

#---------------------------------------------------------------------
# Nix
#
#. $HOME/.nix-profile/etc/profile.d/nix.sh
#
#eval "$(direnv hook bash)"

#---------------------------------------------------------------------
# OPAM (OCaml package manager)
#
eval $(opam env)

#---------------------------------------------------------------------
# Rust
#
. "$HOME/.cargo/env"
