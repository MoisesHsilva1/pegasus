#!/bin/bash

command -v gsettings >/dev/null 2>&1 || exit 0
set_gsetting() { gsettings set "$1" "$2" "$3" >/dev/null 2>&1 || true; }

set_gsetting org.gnome.desktop.wm.keybindings close "['<Super>w']"
set_gsetting org.gnome.desktop.wm.keybindings maximize "['<Super>Up']"
set_gsetting org.gnome.desktop.wm.keybindings begin-resize "['<Super>BackSpace']"
set_gsetting org.gnome.settings-daemon.plugins.media-keys next "['<Shift>AudioPlay']"
set_gsetting org.gnome.desktop.wm.keybindings toggle-fullscreen "['<Shift>F11']"
set_gsetting org.gnome.mutter dynamic-workspaces false
set_gsetting org.gnome.desktop.wm.preferences num-workspaces 4
set_gsetting org.gnome.shell.extensions.dash-to-dock hot-keys false

for slot in 1 2 3 4 5 6 7 8 9; do
  set_gsetting org.gnome.shell.keybindings "switch-to-application-$slot" "['<Alt>$slot']"
done
for slot in 1 2 3 4; do
  set_gsetting org.gnome.desktop.wm.keybindings "switch-to-workspace-$slot" "['<Super>$slot']"
done

# Search Light has precedence on Super+Space. Ulauncher remains available at
# Super+Shift+Space when installed.
set_gsetting org.gnome.desktop.wm.keybindings switch-input-source "@as []"
custom_paths=() custom_names=() custom_commands=() custom_bindings=()
add_custom() {
  custom_paths+=("/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${#custom_paths[@]}/")
  custom_names+=("$1") custom_commands+=("$2") custom_bindings+=("$3")
}

if command -v ulauncher >/dev/null 2>&1 || [ -f "$HOME/.local/share/applications/ulauncher.desktop" ]; then
  add_custom Ulauncher 'sh -c "pgrep -x ulauncher && { ulauncher-toggle || true; } || setsid -f ulauncher"' '<Super><Shift>space'
fi
command -v flameshot >/dev/null 2>&1 && add_custom Flameshot 'flameshot gui' '<Control>Print'
command -v alacritty >/dev/null 2>&1 && add_custom "New Alacritty Window" alacritty '<Shift><Alt>2'
command -v google-chrome >/dev/null 2>&1 && add_custom "New Chrome Window" 'google-chrome --new-window' '<Shift><Alt>1'
if command -v asdcontrol >/dev/null 2>&1; then
  detect='asdcontrol $(asdcontrol --detect /dev/usb/hiddev* 2>/dev/null | grep ^/dev/usb/hiddev | cut -d: -f1)'
  add_custom "Apple Brightness Down (ASDControl)" "sh -c '$detect -- -5000'" '<Control>F1'
  add_custom "Apple Brightness Up (ASDControl)" "sh -c '$detect -- +5000'" '<Control>F2'
  add_custom "Apple Brightness Max (ASDControl)" "sh -c '$detect -- +60000'" '<Control><Shift>F2'
fi

custom_list='['
for path in "${custom_paths[@]}"; do custom_list+="'$path',"; done
custom_list="${custom_list%,}]"
set_gsetting org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$custom_list"
for i in "${!custom_paths[@]}"; do
  schema="org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:${custom_paths[$i]}"
  set_gsetting "$schema" name "${custom_names[$i]}"
  set_gsetting "$schema" command "${custom_commands[$i]}"
  set_gsetting "$schema" binding "${custom_bindings[$i]}"
done
