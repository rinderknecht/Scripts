#!/bin/sh

#set -x

#--------------------------------------------------------------------
# Wrappers for several kind of displays
#
print_newline () {
  if test "$quiet" != "yes"
  then
    echo "$1"
  fi
}

print () {
  if test "$quiet" != "yes"
  then
    echo -n "$1"
  fi
}

fatal_error () {
  echo "$(basename $0): fatal error:"
  echo "$1" 1>&2
  exit 1
}

debug () {
  if test "$debug" = "yes"
  then
    echo -n "$1"
  fi
}

debug_newline () {
  if test "$debug" = "yes"
  then
    echo "$1"
  fi
}

warning () {
  print_newline "$(basename $0): warning:"
  print_newline "$1"
}


#--------------------------------------------------------------------
# Command-line options parsing

# Usage of this script
#
usage () {
  cat <<EOF
Usage: $(basename $0) -o <booklet>.[ps|pdf] <doc>.ps

Convert a PostScript document into an A4  booklet. Utilities
\`psbook' and \`pstops' (also \`ps2pdf' in case of a PDF output) must
be installed and accessible through the environment variable PATH.

Mandatory options
  -o <booklet>.[ps|pdf]      sets the name of the output document
EOF
  exit 1
}


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
    -o)
      if test -n "$output_opt"
      then
        fatal_error "Repeated option -o."
      fi
      output=$2
      shift
      output_opt="-o"
      ;;
    --output=*)
      if test -n "$output_opt"
      then
        fatal_error "Repeated option --output."
      fi
      output=$(expr match "$1" "[^=]*=\(.*\)")
      output_opt="--output"
      ;;
    --output)
      long_short_opt=$1
      break
      ;;
      # Invalid option
      #
    -*)
      fatal_error "Invalid option \"$1\"."
      ;;
      # The PostScript document
      #
     *)
      if test -n "$doc_arg"
      then
        fatal_error "Only one document allowed."
      fi  
      doc=yes
      doc_arg=$1
      ;;
  esac
  shift
done

#--------------------------------------------------------------------
# Checking the command-line options and arguments and applying some of
# them.

# First, we check if the user asks for help.
#
if test "$help" = "yes"
then
  usage
fi

# It is a common mistake to forget the `=' in GNU long-option style.
#
if test -n "$long_short_opt"
then
  fatal_error "Long option style $long_short_opt must be followed by \"=\"."
fi

# Checking the presence of `psbook', `pstops' and `ps2pdf'.
#
IFS=':'
for dir in $PATH; do
  if test -z "$dir"; then dir=.; fi
  if test "$psbook_found" = "no" -a -x "$dir/psbook"
  then
    psbook_found=yes
  fi
  if test "$pstops_found" = "no" -a -x "$dir/pstops"
  then
    pstops_found=yes
  fi
  if test "$ps2pdf_found"  = "no" -a -x "$dir/ps2pdf"
  then
    ps2pdf_found=yes
  fi
done

if test "$psbook_found" = "no"
then
  fatal_error "Utility \`psbook' not found."
fi

if test "$pstops_found" = "no"
then
  fatal_error "Utility \`pstops' not found."
fi

# Checking the presence of the given PostScript document
#
if test -z "$doc_arg"
then
  fatal_error "Give an input PostScript document."
elif test ! -e "$doc_arg"
  then
    fatal_error "Document \"$doc_arg\" is not found."
  else
    doc=$doc_arg
fi

# Checking the output document.
#
if test -z "$output"
then
  fatal_error "Give an ouput document."
else
  if test -e "$output"
  then
    print "$(basename $0): $output already exists; overwrite? [y|N] "
    read answer
    if test "$answer" != "y"
    then
      exit 1
    fi
  fi
  base=$(basename $output .ps)
  if test "$output" = "$base"
  then
    base=$(basename $output .pdf)
    if test "$output" = "$base"
    then
      fatal_error "Output file must have extension .ps or .pdf."
    else
      if test "$ps2pdf_found" = "no"
      then
        fatal_error "Utility \`ps2pdf' not found."
      else
        output_kind=pdf
      fi
    fi
  else
    output_kind=ps
  fi
fi


#--------------------------------------------------------------------
# Main

  psbook $doc \
| pstops -pa4 '4:0@.7L(21cm,00)+1L@.7(21cm,14.8cm),2L@.7(21cm,00)+3L@.7(21cm,14.8cm)' \
> $base.ps

if test "$output_kind" = "pdf"
then
  ps2pdf $base.ps $output
fi
