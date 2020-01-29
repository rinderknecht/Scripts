#!/bin/sh

# This script updates locally our web site before it is remotely
# synchronised using the script rsync_site.sh
#
# Author: Christian Rinderknecht

#set -x

#=====================================================================
# General Settings
# In a future release, $quiet could be passed as an option
#
quiet=no

script=$(basename $0)

#=====================================================================
# Wrappers for several kind of displays
#
print_nl () { if test "$quiet" != "yes"; then printf "$1\n"; fi }

fatal_error () {
  echo "\n$script: fatal error:"
  echo "$1" 1>&2
  exit 1
}

warn () {
 print_nl "\n$script: warning:"
 print_nl "$1"
}

#=====================================================================
# Help
#
usage () {
  cat <<EOF
Usage: $(basename $0) [-h][-d]

Update the web site on the local host.

The following options, if given, must be given only once.

Display control:
  -h, --help       display this help and exit
EOF
  exit 1
}

# Other options:
#   -d, --debug      display configuration of tools

#=====================================================================
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
      # Recursive descent
      #
    # -d | --debug)
    #   debug=yes
    #   debug_opt=$1
    #   ;;
      # Invalid option
      #
    -*)
      fatal_error "Invalid option \"$1\"."
      ;;
      # Additional arguments
      #
     *)
      fatal_error "No argument taken."
      ;;
  esac
  shift
done

#=====================================================================
# Checking the command-line options and arguments and applying some of
# them.

# First, we check if the user asks for help.
#
if test "$help" = "yes"; then usage; fi

#=====================================================================
# Records source updates in $updates and exports updates in
# $updated_exports.
#
# Called by `update_src'
#
# The current directory is assumed to be
# $HOME/public_html/Lectures
#
record_update () {
  updated=$1
  updates=$2
  exports=$3
  updated_exports=$4

#   echo "Entering record_update..."
#   echo "\$updated=[$1]"
#   echo "\$updates=[$2]"
#   echo "\$exports=[$3]"
#   echo "\$updated_exports=[$4]"

  echo "$updated" \
| awk '{ print $2 }' \
| while read update; do \
    new_update=$(expr $update : "'\(.*\)'")
    if test -n "$new_update"; then update=$new_update; fi
    if test -f "$update"
    then update_dir=$(dirname $update)
    else update_dir=
    fi
    if test -n "$update_dir"
    then if test $(basename $update) = $exports
         then echo $update_dir >> $updated_exports
         elif ! (grep -x $update_dir $updates > /dev/null 2>&1)
           then echo $update_dir >> $updates
         fi
    fi
  done
}

#=====================================================================
# Update and/or checkout sources from the Subversion archive
#
# Example of Subversion update:
#
# $ svn update AI
# U  AI/ai.tex
# Updated to revision 603.
# $ svn update IR
# At revision 603.
#
# The current directory is assumed to be
# $HOME/public_html/Lectures
#
update_src () {
  catalog=$1
  updates=$2
  exports=$3
  updated_exports=$4

  if test -s "$catalog"
  then
    rm -f $updates $updated_exports
      sed '/^[ ]*$/d' $catalog \
    | while read lecture; do
        if test -d $lecture
        then
          printf "Updating recursively $(pwd)/$lecture..."
          updated=$(svn update $lecture)
          if test $? -eq 0
          then
            formated=$(echo "$updated" | tr '\n' ' ')
            if test $(expr "$formated" : "At revision") -ne 0
            then echo " no update."
            else echo " done."
                 record_update "$updated" $updates $exports $updated_exports
            fi
          else echo " FAILED. Skipping $lecture."
          fi
        else
          printf "Checking out $(pwd)/$lecture..."
          updated=$(svn checkout file://$HOME/SVN/Lectures/$lecture)
          if test $? -eq 0
          then echo " done."
               record_update "$updated" $updates $exports $updated_exports
          else echo " FAILED. Skipping $lecture."
          fi
        fi
      done
  else echo "No lectures to update or check out."
  fi
}

#=====================================================================
# Update the documents in the updated copies using generic makefiles
#
# The current directory is assumed to be
# $HOME/public_html/Lectures
#
update_doc () {
  catalog=$1
  updates=$2
  exports=$3
  exported_updates=$4
  updated_exports=$5

  rm -f $exported_updates

  if test -s "$catalog"
  then
    sed '/^[ ]*$/d' $catalog \
  | while read lecture; do
      if test -d $lecture
      then
        export_file=$lecture/$exports
        if test -s $export_file
        then
          sed '/^[ ]*$/d' $export_file \
        | while read export_line; do
            paths=$(expr "$export_line" : "[^:]*: *\(.*\)")
            if test -n "$paths"
            then
              for path in $paths; do
                if test "$path" = "."
                then qualified_path=$lecture
                else qualified_path=$lecture/$path
                fi
                updated_src=$(grep -x $qualified_path $updates 2>/dev/null)
                updated_exp=$(grep -x $lecture $updated_exports 2>/dev/null)

                # Remaking the document and the accompanying .phtml
                #
                if test -n "$updated_src" -o -n "$updated_exp"
                then
                  if test -d $qualified_path
                  then
                    echo "*** Entering $qualified_path"
                    echo $qualified_path >> $exported_updates
                    (cd $qualified_path
                     setup.sh
                     if test -f Makefile
                     then
                       doc=$(make -Rrs doc 2>/dev/null)
                       if test -n "$doc"
                       then
                         if test -n "$updated_src"
                         then
                           make -Rrs clean
                           printf "Deleting document parts..."
                           del_parts.sh $doc
                           echo " done."
                           if test "$(basename $qualified_path)" = "Answers"
                           then answers.sh $doc
                           fi
                         fi
                         parts.sh $doc
                       else
                         make -Rrs parts
                       fi
                     else warn "$(pwd)/Makefile not found. Skipping."
                     fi)
                  else warn "Directory $qualified_path not found."
                  fi
                fi
              done
            fi
          done
        fi
      else warn "Directory $lecture in catalog $catalog not found."
      fi
    done
  fi
}

#=====================================================================
# Generating the main section HTML
#
# The current directory is assumed to be
# $HOME/public_html/Lectures
#
update_html () {
  exports=$1
  exported_updates=$2
  updated_exports=$3
  updated_lectures=$4

  rm -f $updated_lectures

#   echo "Entering update_html..."
#   if test -s $updated_exports
#   then
#     echo ".updated_exports exists and is not empty."
#   else
#     echo ".updated_exports does no exist or is empty."
#   fi
#   if test -s $exported_updates
#   then
#     echo ".exported_updates exists and is not empty."
#   else
#     echo ".exported_updates does not exist or is empty."
#   fi

  if test -s $updated_exports -o -s $exported_updates
  then
      cat $updated_exports $exported_updates 2>/dev/null \
    | while read line; do echo $(expr "$line" : "\([^/]*\)"); done \
    | sort -u >| $updated_lectures

      cat $updated_lectures 2>/dev/null \
    | while read lecture; do
        if test -s $lecture/$exports
        then # Perhaps something to publish. Assuming none or one main section.
          index=$lecture/index.html
          printf "Updating $index (XHTML 1.0 Transitional)..."
          echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"" >| $index
          echo "         \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" >> $index
          echo >> $index
          echo "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">" >> $index
          echo >> $index
          echo "<head>" >> $index
          main=$(sed -n -E 's|#[^:]+:[ ]*([^ ]+)[ ]*|\1|p' \
                           $lecture/$exports 2>/dev/null)
          if test -z "$main"
          then # No main section. Let us try $lecture.
             main=.
          fi
          title_file=$(ls $lecture/$main/.*.title 2>/dev/null)
          title=
          if test -n "$title_file"
          then # Assuming only one path and one title for the main section
            title=$(cat $title_file | sed -e "s|\\\'||g" -e "s|\\\^||g" \
                    | tr -d '`' | tr -d '\\' 2>/dev/null)
          fi
          if test -z "$title"; then title=Document; fi
          echo "  <title>$title</title>" >> $index
          echo "    <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\"/>" >> $index
          echo "    <style type=\"text/css\">img {border-width: 0}</style>" >> $index
          echo "</head>" >> $index
          echo >> $index
          echo "<body bgcolor=\"#FFFFFF\">" >> $index
          echo >> $index
          echo "<h3>$title</h3>" >> $index
          echo >> $index
          echo "<ul>" >> $index

            sed '/^[ ]*$/d' $lecture/$exports \
          | while read export_line; do
              section=$(expr "$export_line" : "\([^:]*\):.*")
              main=$(expr "$section" : "#\(.*\)")
              paths=$(expr "$export_line" : "[^:]*: *\(.*\)")
              if test -n "$main"
              then # The main section title is followed by the date
                # Only one path for the main section is assumed
                path=$(echo "$paths" | sed -E 's/^([^ ]+).*$/\1/')
                title_file=$(ls $lecture/$path/.*.title 2>/dev/null)
                base=$(basename $title_file .title)
                base=$(expr $base : "\.\(.*\)")
                if test -f $lecture/$path/.$base.dvi.date
                then
                  last_update=$(cat $lecture/$path/.$base.dvi.date)
                  echo "  <li>$main (last updated $last_update)" >> $index
                else echo "  <li>$main" >> $index
                fi
              elif test -n "$section"
                then echo "  <li>$section" >> $index
              fi
              if test -n "$main" -o -n "$section"
              then
                echo "    <ul>" >> $index
                for path in $paths; do
                  html=$(ls $lecture/$path/*.phtml 2>/dev/null)
                  if test -n "$html" # Assuming only one *.phtml
                  then
                    if test $path = .
                    then # Handmade
                      cat $html >> $index
                    else # AutomaTeX
                        cat $html \
                      | sed -E -e "s|([^\"]*)\.ps|$path/\1.ps|g" \
                               -e "s|([^\"]*)\.pdf|$path/\1.pdf|g" >> $index
                    fi
                  fi
                done
                echo "    </ul>" >> $index
                echo "  </li>" >> $index
              fi
            done

          echo "</ul>" >> $index
          echo >> $index
          echo "<hr/>" >> $index
          echo >> $index
          echo "<p>This file has been automatically generated $(date).</p>" >> $index
          echo >> $index
          echo "<p>" >> $index
          echo "  <a href=\"http://validator.w3.org/check?uri=referer\">" >> $index
          echo "  <img src=\"http://www.w3.org/Icons/valid-html401\"" >> $index
          echo "       alt=\"Valid HTML 4.01 Transitional\" height=\"31\" width=\"88\"/>" >> $index
          echo "  </a>" >> $index
          echo "</p>" >> $index
          echo >> $index
          echo "</body>" >> $index
          echo "</html>" >> $index
          echo " done."
        fi
      done
  fi
}

#=====================================================================
# Update the main HTML
#
# The current directory is assumed to be
# $HOME/public_html/Lectures
#
update_root_idx () {
  catalog=$1
  exports=$2
  updated_lectures=$3
  updated_catalog=$4
  index=index.html

  if test -s $updated_lectures -o -f $updated_catalog
  then
    printf "Updating the root index (XHTML 1.0 Transitional)..."
    echo "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Transitional//EN\"" >| $index
    echo "         \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd\">" >> $index
    echo >> $index
    echo "<html xmlns=\"http://www.w3.org/1999/xhtml\" xml:lang=\"en\" lang=\"en\">" >> $index
    echo >> $index
    echo "<head>" >> $index
    echo "  <title>Teachings in Computer Science by Christian Rinderknecht</title>" >> $index
    echo "  <meta http-equiv=\"Content-Type\" content=\"text/html;charset=utf-8\"/>" >> $index
    echo "  <style type=\"text/css\">img {border-width: 0}</style>" >> $index
    echo "</head>" >> $index
    echo >> $index
    echo "<body bgcolor=\"#FFFFFF\">" >> $index
    echo >> $index
    echo "  <h2>Teachings in Computer Science</h2>" >> $index
    echo "  <h3>by Christian Rinderknecht</h3>" >> $index
    echo >> $index
    echo "  <ul>" >> $index

      sed '/^[ ]*$/d' $catalog \
    | while read lecture; do
        if test -s $lecture/$exports
        then
          if test -f $lecture/index.html
          then
            main=$(sed -n -E 's|#[^:]+:[ ]*([^ ]+)[ ]*|\1|p' $lecture/$exports 2>/dev/null)
            if test -z "$main"
            then # No main section. Let us try $lecture.
              main=.
            fi
            lang_file=$(ls $lecture/$main/.*.lang 2>/dev/null)
            if test -n "$lang_file" -a -f "$lang_file"
            then lang=" ($(cat $lang_file))"
            else lang=
            fi
            title_file=$(ls $lecture/$main/.*.title 2>/dev/null)
            if test -n "$title_file"
            then # Assuming only one title
              title=$(cat $title_file)
              if test -z "$title"
              then
                title='    <font color="red">The title is missing! Please report.</font>'
                warn "Title of lecture $lecture not found. Skipping."
              fi
            else
              title='    <font color="red">The title is missing! Please report.</font>'
              warn "Title of lecture $lecture not found. Skipping."
            fi
              echo "    <li><a href=\"$lecture/index.html\">$title$lang</a></li>" \
            | sed -e "s|\\\'||g" -e "s|\\\^||g" \
            | tr -d '`' | tr -d '\\' >> $index
            echo >> $index
          else warn "File $lecture/index.html not found."
          fi
        elif test ! -e $lecture/$exports
          then warn "File $lecture/$exports not found."
        fi
      done

    echo "  </ul>" >> $index
    echo >> $index
    echo "<p>This file has been automatically generated $(date).</p>" >> $index
    echo >> $index
    echo "<hr/>" >> $index
    echo >> $index
    echo "<p>" >> $index
    echo "  <a href=\"http://validator.w3.org/check?uri=referer\">" >> $index
    echo "  <img src=\"http://www.w3.org/Icons/valid-html401\"" >> $index
    echo "       alt=\"Valid HTML 4.01 Transitional\" height=\"31\" width=\"88\"/>" >> $index
    echo "  </a>" >> $index
    echo "</p>" >> $index
    echo >> $index
    echo "</body>" >> $index
    echo "</html>" >> $index
    echo " done."
  fi
}

#=====================================================================
# Computing the prefix-free ordered set of directory names in a file.
#
# The method consists in, firstly, sorting the paths increasingly;
# secondly, scanning the sorted list with a two-line window: if the
# first path is not a prefix of the second, it is output; the window
# is then slided by one line. If there is no second name to compare
# with, the only name in the window is output and the process is over.
#
prefix_free () {
  thefile=$1

  sort -o $thefile -u $thefile
  rm -f $thefile.prefix-free
  current_path=$(head -n 1 $thefile)

    cat $thefile \
  | (while read new_path; do
      if test "${new_path##$current_path}" = "$new_path"
      then # $current_path is not a prefix of $new_path
        echo $current_path >> $thefile.prefix-free
      fi
      current_path=$new_path
    done;
    echo $current_path >> $thefile.prefix-free)
}

#=====================================================================
# Taking a list of paths and outputting all the intermediary paths.
#
distribute () {
  mirrors=../$1
  paths=$2

  rm -f $2.dist

    cat $2 \
  | while read path; do
      base=$path
      until test $base = $1; do
        echo $base >> $2.dist
        base=$(dirname $base)
      done
    done

  sort -o $2.dist -u $2.dist
}

#=====================================================================
# Updating the mirror of the Web site
#
# The current directory is assumed to be
# $HOME/public_html/Lectures
#
update_mirror () {
  catalog=$1
  exports=$2
  exported_updates=$3
  updated_lectures=$4
  mirror=../$5
  exported_dirs=$6
  mirrored_dirs=$7
  updated_catalog=$8
  updated_exports=$9

  rm -f $exported_dirs $exported_dirs.dist $mirrored_dirs .removed

  # updated_lectures <- $cat_path $updated_exports $exported_updates

#   echo "Entering update_mirror..."
#   if test -s $updated_lectures
#   then
#     echo ".updated_lectures exists and is not empty."
#   else
#     echo ".updated_lectures does not exist or is empty."
#   fi

  if test -s $updated_lectures -o -f $updated_catalog -o ! -d $mirror
  then
    # Mirroring the root index
    #
    printf "Mirroring the root index..."
    mkdir -p $mirror
    cp -f index.html $mirror
    echo " done."

    # Copying all the exported updates
    #
      cat $updated_lectures $exported_updates 2>/dev/null \
    | while read path; do
        backup=$(ls $path/*.java $path/*.pdf $path/*.html $path/*.xml \
                    $path/*.xsl $path/*.erl $path/*.ert $path/*.P $path/*.pl \
                    $path/*.c $path/*.txt $path/*.dtd 2>/dev/null)
        if test -n "$backup"
        then
          printf "Mirroring $path..."
          mkdir -p $mirror/$path
            echo $backup \
          | while read a_file; do cp -f $a_file $mirror/$path 2>/dev/null; done
          echo " done."
        fi
      done

    # Collecting the exported directories, sorting them and adding all
    # the intermediate directories.
    #
      sed '/^[ ]*$/d' $catalog 2>/dev/null \
    | while read lecture; do
        if test -d $lecture
        then # Some published lecture
            sed '/^[ ]*$/d' $lecture/$exports 2>/dev/null \
          | while read export_line; do
              paths=$(expr "$export_line" : "[^:]*: *\(.*\)")
              if test -n "$paths"
              then # Indeed, something published
                for path in $paths; do
                  if test "$path" = "."
                  then echo $mirror/$lecture >> $exported_dirs
                  else echo $mirror/$lecture/$path >> $exported_dirs
                  fi
                done
              fi
            done
        fi
     done
     sort -o $exported_dirs -u $exported_dirs
     distribute $mirror $exported_dirs

    # Collecting all the current directories in the mirror and removing
    # all the names which are prefix of another.
    #
    find $mirror/* -type d >> $mirrored_dirs
    sort -o $mirrored_dirs -u $mirrored_dirs

    # Finding the directories which are in the mirror but which are not
    # exported: they must be removed from the mirror.
    #
    comm -2 -3 $mirrored_dirs $exported_dirs.dist >| .removed

    if test -s .removed
    then
        cat .removed \
      | while read path; do
          printf "Removing ${path#$mirror/} from the mirror..."
          rm -fr $path
          echo " done."
        done
    else rm -f .removed
    fi

    # Finding the directories which are exported but which are not
    # in the mirror: they must be added to the mirror.
    #
    comm -1 -3 $mirrored_dirs $exported_dirs.dist >| .added

    if test -s .added
    then cat .added \
       | while read path; do
           short_path=${path#$mirror/}
           backup=$(ls $short_path/*.pdf $short_path/*.html $short_path/*.xml \
                             $short_path/*.xsl $short_path/*.erl $short_path/*.ert \
                             $short_path/*.P $short_path/*.pl $short_path/*.c \
                             $short_path/*.txt 2>/dev/null)
           if test -n "$backup"
           then printf "Mirroring $short_path..."
                mkdir -p $path
                cp -f $short_path/*.pdf $short_path/*.html $short_path/*.xml \
                      $short_path/*.xsl $short_path/*.erl $short_path/*.ert \
                      $short_path/*.P $short_path/*.pl $short_path/*.c \
                      $short_path/*.txt $path 2>/dev/null
                echo " done."
           fi
         done
    else rm -f .added
    fi

  fi
}

#=====================================================================
# Update the user's tools needed for running this script
#
update_tools () {
  echo "Updating tools on the file server $1: "
  svn update $HOME/devel $HOME/Makefiles $HOME/LaTeX
}

#=====================================================================
#
#
update_lectures () {
  updated_catalog=$1

  catalog=.catalog
  updates=.updates
  exports=.exports
  exported_updates=.exported_updates
  updated_exports=.updated_exports
  updated_lectures=.updated_lectures
  mirror=Mirror
  exported_dirs=.exported_dirs
  mirrored_dirs=.mirrored_dirs

  (cd $HOME/public_html/Lectures
  update_src      $catalog $updates $exports $updated_exports
  update_doc      $catalog $updates $exports $exported_updates $updated_exports
  update_html     $exports $exported_updates $updated_exports $updated_lectures
  update_root_idx $catalog $exports $updated_lectures $updated_catalog
  update_mirror   $catalog $exports $exported_updates \
                  $updated_lectures $mirror $exported_dirs $mirrored_dirs \
                  $updated_catalog $updated_exports)
}

#=====================================================================
#
#
update_root () {
  updated_catalog=.updated_catalog
  public_html=$HOME/public_html
  lectures=$public_html/Lectures

  (cd $HOME
   if test -d $HOME/public_html
   then
     printf "Updating $HOME/public_html..."
     updated=$(svn update $public_html)
     if test $? -eq 0
     then formated=$(echo "$updated" | tr '\n' ' ')
          if test $(expr "$formated" : "At revision") -ne 0
          then echo " no update."
          else echo " done."
               symlinks.sh --set public_html
               symlinks.sh --set --recursive public_html/Software
          fi
     else echo " FAILED. Aborting."
          exit 1
     fi
   else printf "Checking out $HOME/public_html..."
        svn checkout file://$HOME/SVN/public_html
        if test $? -eq 0
        then echo " done."
             symlinks.sh --set public_html
             symlinks.sh --set --recursive public_html/Software
        else echo " FAILED. Aborting."
             exit 1
        fi
   fi

   if test -d $lectures
   then
     rm -f $lectures/$updated_catalog

     printf "Updating $lectures..."
     updated=$(svn update --non-recursive $lectures)
     rm -f $updated_catalog
     if test $? -eq 0
     then formated=$(echo "$updated" | tr '\n' ' ')
          if test $(expr "$formated" : "At revision") -ne 0
          then echo " no update."
          else echo " done."
               touch $lectures/$updated_catalog
          fi
          update_lectures $updated_catalog
     else echo " FAILED. Skipping."
     fi
   else
     printf "Checking out $lectures..."
     (cd $public_html > /dev/null
      svn checkout --non-recursive file://$HOME/SVN/Lectures > /dev/null
      if test $? -eq 0
      then echo " done."
           touch $lectures/$updated_catalog
           update_lectures $updated_catalog
      else echo " FAILED. Skipping."
      fi)
   fi)
}

#=====================================================================
# Updating the CV
#
update_cv () {
  echo "Updating CV on the file server: "
  svn update $HOME/CV/English
  (cd $HOME
   if test -d $HOME/public_html/CV
   then (cd $HOME/public_html/CV
         if test -f Makefile
         then echo "Entering $HOME/public_html/CV..."
              symlinks.sh --set
              make -Rrs all
         fi)
   fi)
}

#=====================================================================
# Main
#
update_tools $(uname -n)
update_root
update_cv
