# See .bashrc

if test -f $HOME/.bashrc;
then
  # If the current shell is interactive, echo a trace.
  #
#  case "$-" in
#   *i*) echo "Sourcing $HOME/.bash_profile...";;
#  esac
  source $HOME/.bashrc
fi
