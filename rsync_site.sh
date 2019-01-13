#!/bin/sh

# This script synchronises the remote, server-side web site with the
# source, local updated version (using update_site.sh).
#
# Author: Christian Rinderknecht

#set -x

# =====================================================================
# General Settings

# In a future release, $quiet could be passed as an option
#
quiet=no

script=$(basename $0)

# =====================================================================
# Wrappers for several kind of displays
#
print_nl () { if test "$quiet" != "yes"; then echo "$1"; fi }

fatal_error () {
  echo "$script: fatal error:"
  echo "$1" 1>&2
  exit 1
}


# =====================================================================
# Help
#
usage () {
  cat <<EOF
Usage: $(basename $0) [-h][-d] [<IP address> | <hostname>]

Update the web site locally and synchronise if with <hostname>.

The following options, if given, must be given only once. 

Display control:
  -h, --help       display this help and exit

Other options:
  -d, --debug      display configuration of tools
EOF
  exit 1
}

# =====================================================================
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
    -d | --debug)
      debug=yes
      debug_opt=$1
      ;;
      # Invalid option
      #
    -*)
      fatal_error "Invalid option \"$1\"."
      ;;
      # The hostname
      #
     *)
      if test -n "$hostname_arg"
      then fatal_error "Only one hostname allowed."
      fi  
      hostname=yes
      hostname_arg=$1
      ;;
  esac
  shift
done

# =====================================================================
# Checking the command-line options and arguments and applying some of
# them.

# First, we check if the user asks for help.
#
if test "$help" = "yes"; then usage; fi

if test -z "$hostname"
then fatal_error "web server IP or hostname is missing."
fi

# =====================================================================
# Main
#
print_nl "*** Updating the local mirror:"
update_site.sh

print_nl "*** Synchronising ~/public_html with $hostname_arg:public_html:"
rsync --archive \
      --copy-links \
      --keep-dirlinks \
      --verbose \
      --exclude=Lectures \
      --exclude=.svn \
      --delete \
      --delete-excluded \
      ~/public_html \
      rinderkn@$hostname_arg:.
