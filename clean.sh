#!/bin/sh

# This script detects our build architecture, the makefiles which have
# a cleaning feature (clean and/or distclean phony entries) and
# call/update them.
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

print () { if test "$quiet" != "yes"; then printf "$1"; fi }

fatal_error () {
  echo "$script: fatal error:"
  echo "$1" 1>&2
  exit 1
}

warn () {
 print_nl "$script: warning:"
 print_nl "$1" 
}

# =====================================================================
# Help
#
usage () {
  cat <<EOF
Usage: $(basename $0) [-h][-q][-v][-d][-r][<path> ... <path>]

Deletes the symbolic links specified in the files \`<path>/.links'
(see script \`symlinks.sh') and clean up the files produced by LaTeX
(using AutomaTeX) and OCaml projects, as well as temporary files
produced by Subversion (\`svn-commit.tmp', \`svn-commit.tmp~' and
\`#svn-commit.tmp#').

Basically, what this script does is to check whether
a Makefile is present and/or a <path>/.links file. Hence, if symlinks
are specified, the links are set, then if a Makefile is present, the
GNU phony target \`distclean' is updated, finally, if symlinks were
set, they are removed.

If no <path> is given, one implicit path is defaulted to \`.'

The following options, if given, must be given only once. 

Display control:
  -h, --help       display this help and exit
  -q, --quiet      do not print any kind of message
  -v, --verbose    display more information (even if -q is set)

Other options:
  -r, --recursive  recursively descends from each <path> included
  -L, --no-links   do not remove symbolic links
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
      help_opt=$1
      ;;
      # Display more information
      #
    -v | --verbose)
      verbose_opt=$1
      ;;
      # Quiet
      #
    -q | --quiet)
      quiet_opt=$1
      ;;
      # Recursive descent
      #
    -r | --recursive)
      if test -n "$recursive_opt"
      then fatal_error "Repeated option --recursive (-r). Skipped."
      fi
      recursive_opt=$1
      ;;
      # Skip symbolic links
      #
    -L | --no-links)
      no_links_opt=$1
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
      # The paths
      #
     *)
      if test -n "$paths_arg"
      then paths_arg="$paths_arg $1"
      else paths_arg=$1
      fi  
      ;;
  esac
  shift
done

# =====================================================================
# Checking the command-line options and arguments and applying some of
# them.

# First, we check if the user asks for help.
#
if test -n "$help_opt"; then usage; fi

# Checking whether the given paths are actual directories
#
if test -z "$paths_arg"
then paths=.
else for path in $paths_arg; do
       if test -d $path
       then if test -z "$paths"
            then paths=$path
            else paths="$paths $path"
            fi
       else warn "Path \"$path\" is not a directory. Skipped."
            paths=
       fi
     done
fi

# =====================================================================
# Cleaning the current directory 
#
apply () {
  local entered=no
  (cd $1
  if test $(pwd) != $(echo ~/bin)
  then if test -e .links
       then if test "$1" != "."
            then print_nl "*** Entering $(pwd)"
                 entered=yes
            fi
            setup.sh $verbose_opt $quiet_opt
       fi
       if test -e Makefile
       then if test "$entered" != "yes" -a "$1" != "."
            then print_nl "*** Entering $(pwd)"
                 entered=yes
            fi
            clean_entry=$(grep '^distclean:' Makefile)
            if test -z "$clean_entry"
            then clean_entry=$(grep '^clean:' Makefile)
                 if test -n "$clean_entry"
                 then clean_entry=clean
                 fi
            else clean_entry=distclean
            fi
            if test -n "$clean_entry"
            then if test -n "$verbose_opt"
                 then make -Rrsi $clean_entry VERB=yes
                 else make -Rrsi $clean_entry
                 fi
            fi
       fi
       if test -e .links -a -z "$no_links_opt"
       then symlinks.sh --unset $verbose_opt $quiet_opt
       fi
  fi)  
}

# =====================================================================
# Main
#
if test -n "$paths"
then
  if test -n "$recursive_opt"
  then
    symbolic_links=$(find $paths -name .links -exec dirname {} \;)
    makefiles=$(find $paths -name Makefile -exec dirname {} \;)
    dir_to_check=$(echo $symbolic_links $makefiles \
                   | tr ' ' '\n' | sort -d | uniq | tr '\n' ' ')
    if test -n "$dir_to_check"
    then for subdir in $dir_to_check; do apply $subdir; done
    fi
  else for path in $paths; do apply $path; done
  fi

  svn_tmp=$(find $paths -name '*svn-commit.*tmp*' -type f | tr '\n' ' ')
  if test -n "$svn_tmp"
  then for tmp in $svn_tmp; do
         print "Removing $tmp..."
         rm -f $tmp
         print_nl " done."
       done
  fi
fi

# for path in $paths; do
#   print "Removing backup files..."
#   \rm -rf $path/*~ $path/.*~ $path/\#*\# $path/.\#*\#
#   print_nl " done."
# done
