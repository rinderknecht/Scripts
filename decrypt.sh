#!/bin/sh

# This script analyses a TeX/LaTeX log file and formats the warnings
# and errors in a compact and legible manner.
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
print_nl () { test "$quiet" != "yes" && echo "$1"; }

print () { test "$quiet" != "yes" && printf "$1";  }

fatal_error () {
  echo "$script: fatal error:"
  echo "$1" 1>&2
  exit 1
}

warn () {
 print_nl "$script: warning:"
 print_nl "$1" 
}

debug_nl () { test "$debug" = "yes" && echo "$1"; }

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
      # The TeX/LaTeX log basename
      #
     *)
      if test -n "$log"
      then fatal_error "Only one TeX/LaTeX log file allowed."
      fi
      if test -e "$1"
      then base=yes
           log=$1
      else fatal_error "TeX log ${1} file missing."
      fi
  esac
  shift
done

# =====================================================================
# Help
#
usage () {
  cat <<EOF
Usage: $(basename $0) [-h][-d] <basename>.log

Extracts information from TeX/LaTeX files and corresponding
<basename>.log and/or any BibTeX log (.blg extension).

Display control:
  -h, --help         display this help and exit

Other options:
  -d, --debug        display configuration of tools
EOF
  exit 1
}

test "$help" = "yes" && usage

# =====================================================================
# Get file name
#
SET_FILE () {
  SUFFIXES=$(ls | sed -n -E 's|.*\.([[:alnum:]]+)$|\1|p' \
             | tr -d -C '[:alnum:] \n' | tr ' ' '\n' | sort -d | uniq | tr '\n' ' ')
  e=
  for s in $SUFFIXES; do
    case "$s" in
      ac|aux|cache|dvi|dvi0|status|in|log|log1|bib|blg);;
      *~|*\#);;
      *) e="$e;s|\.$s|\.$s |g";;
    esac
  done
  e="$e;s|\.sty|\.sty |g;s|\.def|\.def |g;s|\.clo|\.clo |g;s|\.cfg|\.cfg |g;s|\.enc|\.enc |g;s|\.chr|\.chr |g;s|\.ldf|\.ldf |g;s|\.fd|\.fd |g;s|\.fdx|\.fdx |g;s|\.mkii|\.mkii |g;s|\.cls|\.cls |g;s|\.bdg|\.bdg |g"
  current=$(head -n ${2} ${1} \
            | sed -e "$e" | tr -d '\n' | perl -pe 's|\(|\n\(|g;s|\)|\n\)\n|g' \
            | tr ' ' '\n' | grep "([[:alnum:]\|/\|\.]\|)" | tr -d '\n')
  next=$(echo $current | perl -pe 's|\(|\n\(|g;s|\)|\)\n|g' \
         | grep -v "(.*)" | tr -d '\n')
  until test "$current" = "$next"; do
    tmp=$current
    current=$next
    next=$(echo $current | perl -pe 's|\(|\n\(|g;s|\)|\)\n|g' \
           | grep -v "(.*)" | tr -d '\n')
  done
  FILE=$(echo $current | tr -d ')' | sed -E 's|.*\(([^\(]+)$|\1|g')
  if test -n "$FILE"
  then dirname_of_file=$(dirname $FILE)
       if test "$dirname_of_file" = "."
       then FILE=$(basename $FILE)
       fi
  fi
}

# =====================================================================
# Errors
#
find_latex_error () {
  latex_error=$(sed -n "s|^! \(.*\)|\1|p" ${1}.${2} 2>/dev/null | head -n 1)
  if test -n "$latex_error"
  then \
    line=$(sed -n -E "s|^l\.([0-9]+).*|\1|p" ${1}.${2} \
           | tr '\n' ' ' | cut -f 1 -d ' ')
    linenum_in_log=$(grep -n '^! .*' ${1}.${2} \
                     | head -n 1 \
                     | sed -n -E 's|^([0-9]*):.*|\1|p')
    linenum_in_log=$(expr $linenum_in_log - 1)
    # runaway_line=$(nl -b a ${1}.${2} \
    #                | sed -n -E "s|^ *([0-9]+).*Runaway argument?|\1|p" \
    #                | tr '\n' ' ' | cut -f 1 -d ' ')
    # if test -n "$runaway_line"
    # then cutting_line_in_log=$runaway_line
    # else cutting_line_in_log=$linenum_in_log
    # fi
    SET_FILE ${1}.${2} $linenum_in_log
    if test -z "$FILE" -o ! -e "$FILE"
    then in_file=
    else in_file=" in $FILE"
    fi
    if test "$latex_error" = "Undefined control sequence."
    then
      line_after=$(grep -A 1 "^! .*" ${1}.${2} 2>/dev/null \
                   | head -n 2 | tail -n 1)
      error_line=$(sed -n -E 's|^l.[[:digit:]]+ (.*)|\1|p' ${1}.${2} \
                   | head -n 1)
      if test "$line_after" = "$error_line"
      then undefined_macro=$(printf %s "$error_line" \
                             | sed -n -E 's|.*(\\[^ ]+).*|\1|p')
      else undefined_macro=$(printf %s "$line_after" \
                             | sed -n -E 's|.*(\\[^ ]+).*|\1|p')
      fi
      if test -n "$undefined_macro"
      then latex_error="Undefined control sequence $undefined_macro."
      fi
    fi
    if test -z "$line"
    then
      if test -z "$FILE" -a -z "$runaway_line"
      then printf %s "  [E] $latex_error"
           printf "\n"
      else
        echo "  [E] Error$in_file:"
        if test -n "$runaway_line"
        then grep -A 1 "^Runaway argument?" ${1}.${2} 2>/dev/null \
           | tail -n 1 | sed -n "s|^\(.*\)$|      \1|p"
        fi
        printf %s "      $latex_error"
        printf "\n"
      fi
    else echo "  [E] Error$in_file at line ${line}:"
         printf %s "      $latex_error"
         printf "\n"
    fi
    linenum_in_log=$(expr $linenum_in_log + 1)
    echo "      => Check line $linenum_in_log in ${1}.log."
    if test -n "$runaway_line" -a "$FILE" != ${1}.tex
    then echo "      => Check the included or input file."
    fi
  fi
}

# =====================================================================
# Citations
#
advice () {
  if test -z "${3}"
  then
    printf "      => Create a bibliography and/or call \\\bibliography in ${2}.tex.\n"
  else
    all_bib=$(ls *.bib 2>/dev/null)
    if test -z "$all_bib"
    then
      case ${1} in
        1) echo "      => Check spelling or add corresponding entry.";;
        *) echo "      => Check spellings or add corresponding entries.";;
      esac
    else
      case ${1} in
        1) printf "      => Check spelling, add entry or add an argument to \\\bibliography.\n";;
        *) printf "      => Check spellings, add entries or add arguments to \\\bibliography.\n";;
      esac
    fi
  fi
}

PRINT_undef_cit () {
  slave_bib=$(ls *.bib 2>/dev/null)
  case $(echo ${3} | wc -w | tr -d ' ') in
    0|"") ;;
    1) echo "  [W] Undefined citation \`${3}'."
       advice 1 ${2} "$slave_bib";;
    2) echo "  [W] Undefined citations \`"$(echo ${3} | sed "s| |' and \`|g")"'."
       advice 2 ${2} "$slave_bib";;
    *) echo "  [W] Undefined citations: \`"$(echo ${3} | sed "s| |',\`|g")"'."
       advice many ${2} "$slave_bib";;
  esac
  case $(echo ${3} | wc -w | tr -d ' ') in
    0|"") ;;
    *) SET_slave_tex ${2}
       if test -n "$slave_tex" -o -n "$slave_bib"
       then
         for file in $slave_tex $slave_bib; do
           citations=
           for citation in ${3}; do
             if grep "\\\cite\(\[.*\]\)\?[{].*,\?$citation,\?.*[}]" $file >/dev/null 2>&1
             then citations="$citations $citation"
             fi
           done
           citations=$(echo $citations | sed -n "s|^ *\(.*\) *$|\1|p")
           case $(echo $citations | wc -w | tr -d ' ') in
             0|"") ;;
             1) echo "         *" $(echo $file | sed 's| |,|g') \
                     "cites \`$citations'.";;
             2) echo "         *" $(echo $file | sed 's| |,|g') \
                     "cite \`"$(echo $citations | sed "s| |' and \`|g")"'.";;
             *) echo "         *" $(echo $file | sed 's| |,|g') \
                     "cite \`"$(echo $citations | sed "s| |',\`|g")"'.";;
           esac
         done
       fi;;
  esac
}

# =====================================================================
# Warnings and errors in bibliographies
#
SET_slave_base_blg () {
  slave_blg=$(ls *.blg 2>/dev/null)
  if test -n "$slave_blg"
  then slave_base_blg=
       for base_blg in $slave_blg; do
         if test -z "$slave_base_blg"
         then slave_base_blg=$(basename $base_blg .blg)
         else slave_base_blg="$slave_base_blg $(basename $base_blg .blg)"
         fi
       done
  fi
}

SET_warnings_in_blg () {
  blg_files=
  for blg_base_file in ${1}; do
    if test -z "$blg_files"
    then blg_files=$blg_base_file.blg
    else blg_files="$blg_files $blg_base_file.blg"
    fi
  done
  warnings_in_blg=$(sed -n 's|^Warning--\(.*\)|\1|p' $blg_files 2>/dev/null)
}

SET_generic_warnings_in_blg () {
  if test -n "$warnings_in_blg"
  then generic_warnings_in_blg=$(echo "$warnings_in_blg" \
     | grep -v -e "I didn.t find a database entry for .*" 2>/dev/null)
  fi
}

PRINT_generic_warnings_in_blg () {
  if test -n "$generic_warnings_in_blg"
  then echo "$generic_warnings_in_blg" \
     | while read warning; do
         entry=$(echo $warning | sed -n 's|.* in \(.*\)|\1|p' 2>/dev/null)
         if test -n "$entry"
         then
           bibs_with_entry=$(grep -l "{$entry," $bib 2>/dev/null)
           case $(echo $bibs_with_entry | wc -w | tr -d ' ') in
             0|"") echo "  [W] $warning.";;
             1) case $(echo $bib | wc -w | tr -d ' ') in
                  0|"");;
                  1) echo "  [W] $warning.";;
                  *) echo "  [W] $warning of $bibs_with_entry.";;
                esac;;
             2) echo "  [W] $warning of $(echo $bibs_with_entry | sed 's| | and |g').";;
             *) echo "  [W] $warning of $(echo $bibs_with_entry | sed 's| |,|g').";;
           esac
         else echo "  [W] $warning."
         fi
      done
  fi
}

errors_in_blg () {
  case ${1} in
    0|"") ;;
    *) if grep 'I found no \\\bibstyle command' $blg >/dev/null 2>&1;
       then printf "  [E] \\\bibliographystyle is missing:\n"
            echo "      => Choose a style and add a call."
       fi
       if grep 'I found no \\\citation commands' $blg  >/dev/null 2>&1
       then printf "  [E] \\\cite calls are missing:\n"
            printf "      => Add citations or use \\\nocite.\n"
       fi
       missing_bst=$(sed -n "s|I couldn't open style file \(.*\)|\1|p" $blg)
       if test "$missing_bst" != ""
       then echo "  [E] Bibliography style file ${missing_bst} is missing."
            echo "      (This error is counted twice.)"
            echo "      => Check spelling or make this file available."
       fi
       grep "A bad cross reference" $blg
       all_errors=$(grep -e "^[[:alpha:]][^-]*---line .*" $blg 2>/dev/null)
       for b in ${1}; do
         repeated=$(echo "$all_errors" \
           | sed -n "s|Repeated entry---line \(.*\) of file $b.bib|\1|p" $blg \
           | sort -n | uniq | tr '\n' ' ' | sed -n "s|^ *\(.*\) $|\1|p")
         repeated_entries=
           for line in $repeated; do
             repeated_entry=$(nl -b a $b.bib \
               | sed -n "s|^ *$line[^0-9].*@.*[{]\(.*\),.*|\1|p")
             repeated_entries="$repeated_entries"$(printf '\n')"$repeated_entry"
           done
         repeated_entries=$(echo "$repeated_entries" \
                            | sort -d | uniq | tr '\n' ' ' \
                            | sed -n "s|^ *\(.*\) $|\1|p")
         case $(echo $repeated_entries | wc -w | tr -d ' ') in
           0|"") ;;
           1) aux="\`$repeated_entries'"
              echo "  [E] Repeated entry $aux"};;
           2) aux="\`"$(echo $repeated_entries | sed "s| |' and \`|g")"'"
              echo "  [E] Repeated entries $aux";;
           *) aux="\`"$(echo $repeated_entries | sed "s| |',\`|g")"'"
              echo "  [E] Repeated entries: $aux"};;
         esac
         case $(echo $repeated | wc -w | tr -d ' ') in
           0|"") ;;
           1) echo " in ${b}.bib at line $repeated."
              echo "      => Merge entries or rename or remove the redundant one.";;
           2) echo "      in ${b}.bib at lines $(echo $repeated | sed 's| | and |g')."
              echo "      => Merge entries or rename or remove the redundant one.";;
           *) echo "      in ${b}.bib at lines $(echo $repeated | sed 's| |,|g')."
              echo "      => Merge entries or rename or remove the redundant one.";;
         esac
       done
       other_errors=$(echo "$all_errors" \
         | grep -v -e "^Repeated entry---line .*" 2>/dev/null)
       if test -n "$other_errors"
       then
           echo "$other_errors" \
         | while read err; do
              msg=$(echo $err \
                    | sed -E "s=^(.*)---line ([0-9]+) (of file ([[:alnum:]|_|.]+))?.*=  [E] \1 at line \2 in file \4.=g" \
                           2>/dev/null)
              echo "$msg"
           done
       else
         two_lines_errors=$(grep -B 1 "^[-][-][-]line" $blg | sed 's|^--$||g')
         if test -n "$two_lines_errors"
         then
             skip_iter=no
             echo "$two_lines_errors" \
           | while read err; do
               if test $skip_iter = no
               then
                 if test -n "$err"
                 then
                   aux=$(expr "$err" : "I couldn't open style file \(.*\)")
                   if test -z "$aux"
                   then
                     skip_iter=no
                     msg=$(echo "$err" | sed -n "s|^\([^-].*\)|  [E] \1|p")
                     if test -n "$msg"
                     then echo "$msg"
                     else
                       msg=$(echo "$err" \
                             | sed -n -E "s%^---line ([0-9]+) (of file ([[:alnum:]|_|.]+))?.*%      => Check line \1 in file \3.%p" \
                                    2>/dev/null)
                       if test -n "$msg"
                       then echo "$msg"
                       fi
                     fi
                   else skip_iter=yes
                   fi
                 fi
               else skip_iter=no
               fi
             done
         fi
       fi;;
  esac        
}

# =====================================================================
# Labels and references
#
SET_slave_tex () {
  slave_tex=$(ls *.tex 2>/dev/null | tr ' ' '\n' | grep \.tex \
              | while read tex_file; do \
                  if test $tex_file != ${1}; \
                  then echo $tex_file; \
                  fi; \
                done)
}

undefined_ref () {
  undefined_ref=$(sed -n -E \
    "s|LaTeX Warning: Reference \`([^ ]+)' .*|\1|p" ${1}.log \
    2>/dev/null \
  | sort -d | uniq | tr '\n' ' ' | sed -n "s|^ *\(.*\) $|\1|p")
  case $(echo $undefined_ref | wc -w | tr -d ' ') in
    0|"") ;;
    1) echo "  [W] Undefined reference \`$undefined_ref'."
       printf "      => Check spelling or add corresponding \\\label.\n";;
    2) echo "  [W] Undefined references" \
            "\`"$(echo $undefined_ref | sed "s| |' and \`|g")"'."
       printf "      => Check spellings or add corresponding \\\label.\n";;
    *) echo "  [W] Undefined references:" \
            "\`"$(echo $undefined_ref | sed "s| |',\`|g")"'."
       printf "      => Check spellings or add corresponding \\\label.\n";;
  esac
  case $(echo $undefined_ref | wc -w | tr -d ' ') in
    0|"") ;;
    *) SET_slave_tex ${1}
       slave_bib=$(ls *.bib 2>/dev/null)
       for file in $slave_tex $slave_bib; do
         references=
         for reference in $undefined_ref; do
           if grep "\\\\\(v\?page\)\?v\?ref[{]$reference[}]" $file > /dev/null 2>&1
           then references="$references $reference"
           fi
         done
         references=$(echo $references | sed -n "s|^ *\(.*\) *$|\1|p")
         case $(echo $references | wc -w | tr -d ' ') in
           0|"") ;;
           1) echo "         *" $(echo $file | sed 's| |,|g') \
                   "refers to \`$references'.";;
           2) echo "         *" $(echo $file | sed 's| |,|g') \
                   "refers to" "\`"$(echo $references | sed "s| |' and \`|g")"'.";;
           *) echo "         *" $(echo $file | sed 's| |,|g') \
                   "refers to:" "\`"$(echo $references | sed "s| |',\`|g")"'.";;
         esac
       done;;
  esac
}

SET_undefined_citations () {
  undefined_citations=$(sed -n \
    "s|LaTeX Warning: Citation \`\([^ ]\+\)' .*|\1|p" ${1}.log 2>/dev/null \
  | sort -d | uniq | tr '\n' ' ' | sed -n "s|^ *\(.*\) $|\1|p")
}

find_all_missing_cit () {
  SET_undefined_citations ${1}
  PRINT_undef_cit undefined_citations ${1} "$undefined_citations"
}

# =====================================================================
# Detailed report of underfulls and overfulls in .log
#
SET_page () {
  page=$(head -n ${2} ${1} 2>/dev/null \
         | tr -d '\n' | tr -d ' ' \
         | sed -n -E 's|.*\[([0-9]+)\].*|\1|p' 2>/dev/null)
  if test -z "$page"; then page=0; fi
  page=$(expr $page + 1 2>/dev/null)
  if test $? -ne 0; then page=; fi
}

hbox_init () {
  linenum_in_log=$(echo "$line" | sed -n 's|^\(.*\):.*|\1|p')
  line_in_log=$(sed -n "$linenum_in_log p" ${1}.log)
  linenum_in_tex=$(echo "$line_in_log" \
                   | sed -E -n 's|.* (line [0-9]+)|\1|p')
  if test -z "$linenum_in_tex"
  then
    linenum_in_tex=$(echo "$line_in_log" \
                     | sed -E -n 's|.* (lines [0-9]+--[0-9]+)$|\1|p')
  fi
}

SET_message () {
  from=$(expr $linenum_in_log + 1)
  to=$(expr $linenum_in_log + 10)
  chunk="$(sed -n "$from,$to p" ${1}.log)"
  message_size=$(echo $chunk | grep "^ \[\]\$" -n -m 1 \
                 | sed -n 's|\([0-9]*\):.*|\1|p')
  if test -n "$message_size"
  then message_size=$(expr $message_size - 1)
      message=$(echo "$chunk" | head -n $message_size)
  fi
}

u_vbox () {
  linenum_in_log=$(echo "$line" | sed -n 's|^\(.*\):.*|\1|p')
  line_in_log=$(sed -n "$linenum_in_log p" ${1}.log)
  badness=$(echo "$line_in_log" | sed -n 's|.*\((badness .*)\).*|\1|p')
  SET_page ${1}.log $linenum_in_log
  cutting_line_in_log=$linenum_in_log
  SET_FILE ${1}.log $linenum_in_log
  if test -z "$FILE"
  then printf "  [W] Underfull \\\vbox $badness at page $page.\n"
  else printf "  [W] Underfull \\\vbox $badness in $FILE.\n"
       echo "      => Check page $page."
  fi
}

PRINT_message () {
  filtered=$(echo "$message" \
              | tr -d '\n' \
              | sed -E -e 's+\\OT1/[[:alnum:]|/|\.]*++g' \
                    -e 's+\\OMS/[[:alnum:]|/|\.]*++g' \
                    -e 's+\\OML/[[:alnum:]|/|\.]*++g' \
                    -e 's+\\T1/[[:alnum:]|/|\.]*++g' \
                    -e 's+\\OMS/[[:alnum:]|/|\.]*++g' \
                    -e 's+\\OMX/[[:alnum:]|/|\.]*++g' \
                    -e 's+\\U/[[:alnum:]|/|\.]*++g' \
                    -e 's+\\OT2/[[:alnum:]|/|\.]*++g' \
                    -e 's+\\PD1/[[:alnum:]|/|\.]*++g' \
                    -e 's|\[\]||g' \
                    -e 's|$[^$]*\$|<maths>|g' \
                    -e 's|$[^$]*$|<maths>|g' \
                    -e 's|\^^[[:alnum:]]*||g' \
                    -e 's|^ *||g' \
                    -e 's|[ ]\+| |g')
  if test -n "$filtered"
  then printf ":\n     $filtered\n"
  else echo "."
  fi
}

u_hbox () {
  hbox_init ${1}
  badness=$(echo "$line_in_log" \
            | sed -E -n 's|.*(\(badness .*\)).*|\1|p')
  SET_page ${1}.log $linenum_in_log
  cutting_line_in_log=$linenum_in_log
  SET_FILE ${1}.log $linenum_in_log
  SET_message ${1} $linenum_in_log
  if test -z "$FILE"
  then echo "  [W] Underfull \\\hbox $badness at page $page."
  else
    if test -z "$linenum_in_tex"
    then printf "  [W] Underfull \\\hbox $badness in $FILE"
    else printf "  [W] Underfull \\\hbox $badness in $FILE at $linenum_in_tex"
    fi
    PRINT_message
    echo "      => Check page $page and line $linenum_in_log in ${1}.log."
  fi
}

o_hbox () {
  hbox_init ${1}
  too_wide=$(echo "$line_in_log" \
             | sed -n 's|.*(\(.*pt\) too wide).*|\1|p')
  SET_page ${1}.log $linenum_in_log
  SET_FILE ${1}.log $linenum_in_log
  SET_message ${1}
  if test -z "$FILE"
  then printf "  [W] Overfull \\\hbox ($too_wide) at page $page.\n"
  else
    if test -z "$linenum_in_tex"
    then printf "  [W] Overfull \\\hbox ($too_wide) in $FILE"
    else printf "  [W] Overfull \\\hbox ($too_wide) in $FILE at $linenum_in_tex"
    fi
    PRINT_message
    echo "      => Check page $page and line $linenum_in_log in ${1}.log."
  fi
}

o_vbox () {
  linenum_in_log=$(echo "$line" | sed -n 's|^\(.*\):.*|\1|p')
  line_in_log=$(sed -n "$linenum_in_log p" ${1}.log)
  too_high=$(echo "$line_in_log" \
             | sed -n 's|.*(\(.*pt\) too high).*|\1|p')
  SET_page ${1}.log $linenum_in_log
  SET_FILE ${1}.log $linenum_in_lig
  if test -z "$FILE"
  then printf "  [W] Overfull \\\vbox ($too_high) at page $page.\n"
  else printf "  [W] Overfull \\\vbox ($too_high) in $FILE."
       echo "      => Check page $page."
  fi
}

slide_overfull () {
  linenum_in_log=$(echo "$line" \
                   | sed -n 's|^\(.*\):LaTeX Warning:.*|\1|p')
  line_in_log=$(sed -n "$linenum_in_log p" ${1}.log)
  page=$(echo "$line_in_log" | sed -n 's|.*Slide \([0-9]\+\).*|\1|p')  
  points=$(echo "$line_in_log" | sed -n 's|.* by \(.*pt\) .*|\1|p')
  SET_FILE ${1}.log $linenum_in_log
  if test -z "$FILE"
  then echo "  [W] Slide overfull ($points) at page $page."
  elif test -e "$FILE"
    then echo "  [W] Slide overfull ($points) in $FILE."
         echo "      => Check page $page."
    else echo "  [W] Slide overfull ($points) at page $page."
         echo "      => Correct previous warning to get the file name."
  fi
}

show_detailed_under_overfulls () {
    grep -n rfull ${1}.log 2>&1 \
  | while read line; do
      slide_overfull=$(echo "$line" \
                       | sed -n 's|LaTeX Warning: Slide .* overfull .*|yes|p')
      if test -z "$slide_overfull" -a "$kind" != "slide_overfull"
      then kind=$(echo "$line" | awk '{ print $1 $2 }')
           case "$kind" in
             [0-9]*:Underfullhbox) u_hbox ${1};;
             [0-9]*:Underfullvbox) u_vbox ${1};;
             [0-9]*:Overfullhbox) o_hbox ${1};;
             [0-9]*:Overfullvbox) o_vbox ${1};;
           esac
      elif test -n "$slide_overfull"
        then kind=slide_overfull
            slide_overfull ${1}
      fi
    done
}

# =====================================================================
# Missing files
#
SET_filtered_missing_files () {
  missing_files=$(sed -n 's|^No file \([^ ]\+\)\.|\1|p' ${2}.log 2>/dev/null)
  filtered_missing_files=
  for file in $missing_files; do
    reject=false
    for suffix in ${1}; do
      without_suffix=$(basename $file .$suffix)
      if test "$file" != "$without_suffix"
      then
        reject=true
        break
      fi
    done
    if test "$reject" = "false"
    then
      filtered_missing_files="$filtered_missing_files $file"
    fi
  done
}

no_file_warning () {
  SET_filtered_missing_files "aux lof bbl toc ind" ${1}
  case $(echo $filtered_missing_files | wc -w | tr -d ' ') in
    0|"");;
    1) echo "  [W] Missing file$filtered_missing_files."
       echo "      => Check the included or input file name.";;
    2) echo "  [W] Missing files $(echo $filtered_missing_files | sed 's| | and |g')."
       echo "      => Check the included or input file names.";;
    *) echo "  [W] Missing files $(echo $filtered_missing_files | sed 's| |,|g')."
       echo "      => Check the included or input file names.";;
  esac
}

# =====================================================================
# Unused LaTeX option
#
unused_latex_option () {
  unused=$(grep -C 1 "Unused global option(s):" ${1}.log)
  if test -n "$unused"
  then echo "  [W]" $(echo $unused | tr '\n' ' ')
  fi
}

# =====================================================================
# Status of document processing
#
show_common_status () {
  if test ! -e ${1}.log
  then
    echo "TeX log file ${1}.log is missing."
  else
    show_detailed_under_overfulls ${1}
    find_latex_error ${1} log
    if test -z "$latex_error"
    then
      no_file_warning ${1}
      undefined_ref ${1}
      find_all_missing_cit ${1}
      multiple_labels=$(sed -n \
        "s|LaTeX Warning: Label \`\(.*\)' multiply defined.|\1|p" ${1}.log 2>/dev/null \
      | sort -d | uniq | tr '\n' ' ' | sed -n "s|^ *\(.*\) $|\1|p")
      case $(echo $multiple_labels | wc -w | tr -d ' ') in
        0|"") ;;
        1) echo "  [W] Multiply-defined label \`$multiple_labels'."
           echo "      => Check spellings or rename or remove all but one occurrence.";;
        2) echo "  [W] Multiply-defined labels" \
                "\`"$(echo $multiple_labels | sed "s| |' and \`|g")"'."
           echo "      => Check spellings or rename or remove all but one occurrence.";;
        *) echo "  [W] Multiply-defined labels" \
                "\`"$(echo $multiple_labels | sed "s| |',\`|g")"'."
           echo "      => Check spellings or rename or remove all but one occurrence.";;
      esac
      unused_latex_option ${1}
      grep 'Package .* Warning' ${1}.log 2>/dev/null
    fi
  fi
}

bib_status () {
  bib=${1}.bib
  case $(echo $bib | wc -w | tr -d ' ') in
    1) echo "Status of bibliography $bib:";;
    2) echo "Status of bibliographies" \
            $(echo $bib | sed 's| | and |g'):;;
    *) echo "Status of bibliographies" \
            $(echo $bib | sed 's| |,|g'):;;
  esac
}

index_status () {
  if test -e ${1}.ilg
  then grep -A 1 Warning ${1}.ilg
       grep -A 1 -i error ${1}.ilg
  fi
}

show_status () {
  show_common_status ${1}
  index_status ${1}
  SET_slave_base_blg ${1}
  if test -n "$slave_base_blg"
  then
    for base_blg in $slave_base_blg; do
      blg=$base_blg.blg
      if test ! -e $blg
      then echo "BibTeX log file $blg is missing."
      else
        bib_status $base_blg
        SET_warnings_in_blg $base_blg
        test -n "$warnings_in_blg" && echo "$warnings_in_blg"
        SET_generic_warnings_in_blg
        PRINT_generic_warnings_in_blg
        num_errors=$(sed -n -E 's=.*(was|were) (.*) error.*=\2=p' \
                               $blg 2>/dev/null)
        errors_in_blg $num_errors
        if test -z "$num_errors" -a -z "$generic_warnings_in_blg"
        then echo "nothing to report."
        fi
      fi
    done
  fi
}

if test -n "$log"
then base_log=$(basename $log .log)
     dir_log=$(dirname $log)
     if test "$dir_log" = "."
     then show_status $base_log
     else show_status $(dirname $log)/$base_log
     fi
else fatal_error "TeX log file missing."
fi