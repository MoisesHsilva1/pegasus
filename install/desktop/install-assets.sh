#!/bin/bash

# Install the portable visual assets used by the macOS-inspired profile.
# Everything is copied below $HOME so another user or host does not inherit
# this workstation's absolute paths.

command -v gsettings >/dev/null 2>&1 || exit 0
pegasus_dir="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"
[ -d "$pegasus_dir" ] || pegasus_dir="$(cd "$(dirname "${BASH_SOURCE[0]}" )/../.." && pwd)"

copy_tree() {
  [ -d "$1" ] || return 0
  mkdir -p "$(dirname "$2")"
  cp -a "$1" "$2" 2>/dev/null || true
}

copy_file() {
  [ -f "$1" ] || return 0
  mkdir -p "$(dirname "$2")"
  cp -f "$1" "$2" 2>/dev/null || true
}

copy_tree "$pegasus_dir/assets/themes/macOS-Pegasus" "$HOME/.local/share/themes/"
copy_tree "$pegasus_dir/assets/icons/macOS" "$HOME/.local/share/icons/"
copy_file "$pegasus_dir/assets/backgrounds/dos-moos/BG1.jpg" "$HOME/.local/share/backgrounds/dos-moos/BG1.jpg"

set_gsetting() { gsettings set "$1" "$2" "$3" >/dev/null 2>&1 || true; }
set_gsetting org.gnome.desktop.interface color-scheme prefer-dark
set_gsetting org.gnome.desktop.interface accent-color green
set_gsetting org.gnome.desktop.interface cursor-theme macOS
set_gsetting org.gnome.desktop.interface cursor-size 24
set_gsetting org.gnome.desktop.interface enable-animations true
set_gsetting org.gnome.shell.extensions.user-theme name macOS-Pegasus
set_gsetting org.gnome.desktop.background picture-uri "file://$HOME/.local/share/backgrounds/dos-moos/BG1.jpg"
set_gsetting org.gnome.desktop.background picture-uri-dark "file://$HOME/.local/share/backgrounds/dos-moos/BG1.jpg"
set_gsetting org.gnome.desktop.background picture-options zoom

