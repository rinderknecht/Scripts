#!/bin/sh

#set -x

#===============================================================
# General Settings

quiet=no
debug=no

script=$(basename $0)

#===============================================================
# Wrappers for displays
#
print_nl () { if test "$quiet" != "yes"; then echo "$1"; fi }

fatal_error () {
  echo "$script: fatal error:"
  echo "$1" 1>&2
  exit 1
}

#===============================================================
# Help
#
usage () {
  cat <<EOF
Usage: $(basename $0) [-h][-q][-d] <hostname.domain>
       $(basename $0) [-h][-q][-d] <IP address>

Synchronise the local replica with the remote replica denoted by
<hostname.domain> or <IP address>, by means of the file synchroniser
Unison.

The following options, if given, must be given only once. 

Display control:
  -h, --help       display this help and exit
  -q, --quiet      do not print any kind of message
  -d, --debug      display configuration of tools
EOF
  exit 1
}

#===============================================================
# Parsing loop
#
while : ; do
  case "$1" in
    "") break;;
      # Help
      #
    -h | --help | -help) 
      help=yes
      help_opt=$1
      ;;
      # Display more information
      #
    -q | --quiet)
      quiet=yes
      quiet_opt=$1
      ;;
    -d | --debug)
      debug=yes
      debug_opt=$1
      ;;
      # Invalid option
      #
    -*)
      fatal_error "Invalid option \"$1\"."
      ;;
      # The remote replica
      #
     *)
      if test -n "$remote_arg"
      then
        fatal_error "Only one remote replica allowed."
      fi  
      remote=yes
      remote_arg=$1
      ;;
  esac
  shift
done

#===============================================================
# Checking the command-line options and arguments and applying 
# some of them.

# First, we check if the user asks for help.
#
if test "$help" = "yes"; then usage; fi

# Checking remote replica
#
if test -z "$remote_arg"
then fatal_error "Remote replica IP or name missing."
fi

#===============================================================
# Auxiliaries
#
local_link () {
  if test "$2" = "rec"
  then 
    printf "Linking recursively in $(hostname):$1..."
    symlinks.sh --quiet --recursive --set $1
  else
    printf "Linking in $(hostname):$1..."
    symlinks.sh --quiet --set $1
  fi
  if test $? -eq 0; then echo " done. "; else echo " FAILED."; fi
}

local_unlink () {
  if test "$2" = "rec"
  then 
    printf "Unlinking recursively in $(hostname):$1..."
    symlinks.sh --quiet --recursive --unset $1
  else
    printf "Unlinking in $(hostname):$1..."
    symlinks.sh --quiet --unset $1
  fi
  if test $? -eq 0; then echo " done. "; else echo " FAILED."; fi
}

remote_link () {
  if test "$2" = "rec"
  then 
    printf "Linking recursively in $remote_arg:$1..."
    ssh $remote_arg \
        /Users/rinderkn/devel/Scripts/symlinks.sh --quiet --recursive --set $1
  else
    printf "Linking in $remote_arg:$1..."
    ssh $remote_arg \
        /Users/rinderkn/devel/Scripts/symlinks.sh --quiet --set $1
  fi
  if test $? -eq 0; then echo " done. "; else echo " FAILED."; fi
}

remote_unlink () {
  if test "$2" = "rec"
  then 
    printf "Unlinking recursively in $remote_arg:$1..."
    ssh $remote_arg \
        /Users/rinderkn/devel/Scripts/symlinks.sh --quiet --recursive --unset $1
  else
    printf "Unlinking in $remote_arg:$1..."
    ssh $remote_arg \
        /Users/rinderkn/devel/Scripts/symlinks.sh --quiet --unset $1
  fi
  if test $? -eq 0; then echo " done. "; else echo " FAILED."; fi
}

local_unison () {
  echo "Running locally Unison..."
  unison $HOME ssh://$remote_arg
}

local_clean () {
  if test "$2" = "rec"
  then 
    printf "Cleaning recursively $(hostname):$1..."
    clean.sh --quiet --recursive $1
  else
    printf "Cleaning $(hostname):$1..."
    clean.sh --quiet $1
  fi
  if test $? -eq 0; then echo " done."; else echo " FAILED."; fi
}

remote_clean () {
  if test "$2" = "rec"
  then 
    printf "Cleaning recursively $remote_arg::$1..."
    ssh $remote_arg \
        /Users/rinderkn/devel/Scripts/clean.sh --quiet --recursive $1
  else
    printf "Cleaning $remote_arg::$1..."
    ssh $remote_arg \
        /Users/rinderkn/devel/Scripts/clean.sh --quiet $1
  fi
  if test $? -eq 0; then echo " done."; else echo " FAILED."; fi
}

#===============================================================
# Main

# Backup of configuration files
#
cp -f ~/.bash_profile       ~/Config/HOME
cp -f ~/.bashrc             ~/Config/HOME
cp -f ~/.emacs              ~/Config/HOME
cp -f ~/.my_dircolors       ~/Config/HOME
cp -f ~/.profile            ~/Config/HOME
cp -f ~/.xmodmap_apple      ~/Config/HOME
cp -f ~/.unison/default.prf ~/Config/Unison

# Unlinking directories to be synchronised
#
local_unlink ~/bin
remote_unlink bin
local_unlink ~/doc
remote_unlink doc
local_unlink ~/tools rec
remote_unlink tools rec
local_unlink ~/public_html
remote_unlink public_html
local_unlink ~/public_html/Software rec
remote_unlink public_html/Software rec
local_unlink ~/public_html/CV
remote_unlink public_html/CV

# Synchronisation
#
local_unison

# Relinking synchronised directories
#
remote_link bin
local_link ~/bin
remote_link doc
local_link ~/doc
remote_link tools rec
local_link ~/tools rec
remote_link public_html
local_link ~/public_html
local_link ~/public_html/Software rec
remote_link public_html/Software rec
local_link ~/public_html/CV
remote_link public_html/CV

# Updating local Subversion working copies
#
svn update ~/CV ~/devel ~/LaTeX ~/Lectures ~/Makefiles ~/pub ~/public_html ~/Research
