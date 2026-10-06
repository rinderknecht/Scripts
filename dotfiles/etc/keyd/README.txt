$ sudo apt install keyd
$ sudo cp ~/git/dotfiles/etc/keyd/default.conf /etc/keyd/default.conf
$ sudo systemctl enable --now keyd
$ sudo keyd reload
$ gsettings set org.gnome.desktop.input-sources xkb-options "['compose:caps']"
