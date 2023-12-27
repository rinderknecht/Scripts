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

# OPAM configuration
. /home/rinderkn/.opam/opam-init/init.sh > /dev/null 2> /dev/null || true

# MacPorts Installer addition on 2014-10-26_at_12:07:39: adding an appropriate PATH variable for use with MacPorts.
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
# Finished adapting your PATH environment variable for use with MacPorts.

if [ -e /home/rinderkn/.nix-profile/etc/profile.d/nix.sh ]; then . /home/rinderkn/.nix-profile/etc/profile.d/nix.sh; fi # added by Nix installer
