#!/bin/sh

xdg-mime default org.gnome.Evince.desktop application/pdf
gio mime application/pdf org.gnome.Evince.desktop

# Check outcome with:
# xdg-mime query default application/pdf
