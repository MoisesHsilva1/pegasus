#!/bin/bash

# Install and configure the non-native extensions used by the Pegasus GNOME
# profile. Extension installation is optional so the rest of Pegasus remains
# usable when a package or gext is unavailable.

command -v gsettings >/dev/null 2>&1 || exit 0
sudo dnf install -y --skip-unavailable gnome-shell-extension-manager libgtop2-devel clutter >/dev/null 2>&1 || true

if ! command -v gext >/dev/null 2>&1 && command -v pipx >/dev/null 2>&1; then
  pipx install gnome-extensions-cli --system-site-packages >/dev/null 2>&1 || true
fi
export PATH="$HOME/.local/bin:$PATH"

extensions=(
  tactile@lundal.io just-perfection-desktop@just-perfection blur-my-shell@aunetx
  space-bar@luchrioh undecorate@sun.wxg@gmail.com tophat@fflewddur.github.io
  AlphabeticalAppGrid@stuarthayhurst appindicatorsupport@rgcjonas.gmail.com
  arcmenu@arcmenu.com compiz-alike-magic-lamp-effect@hermes83.github.com
  compiz-windows-effect@hermes83.github.com wiggly@mojarch dash-to-panel@jderose9.github.com
  search-light@icedman.github.com dash-to-dock@micxgx.gmail.com spotlight@nin
  superbar@Furkan-rgb.github.io
)

if command -v gext >/dev/null 2>&1; then
  for extension in "${extensions[@]}"; do
    gext install "$extension" >/dev/null 2>&1 || true
  done
fi

# Compile schemas in the user profile; this avoids requiring a system-wide
# copy and works on machines where sudo is deliberately unavailable.
schema_root="$HOME/.local/share/gnome-shell/extensions"
schema_dest="$HOME/.local/share/glib-2.0/schemas"
mkdir -p "$schema_dest"
for extension in "${extensions[@]}"; do
  schema_dir="$schema_root/$extension/schemas"
  [ -d "$schema_dir" ] || continue
  find "$schema_dir" -maxdepth 1 -type f -name '*.gschema.xml' \
    -exec cp -f {} "$schema_dest/" \; 2>/dev/null || true
done
glib-compile-schemas "$schema_dest" >/dev/null 2>&1 || true
export GSETTINGS_SCHEMA_DIR="$schema_dest${GSETTINGS_SCHEMA_DIR:+:$GSETTINGS_SCHEMA_DIR}"

if command -v gnome-extensions >/dev/null 2>&1; then
  for extension in "${extensions[@]}"; do
    gnome-extensions enable "$extension" >/dev/null 2>&1 || true
  done
fi

# Avoid Ubuntu defaults when this script is reused on an Ubuntu-derived test
# image; Fedora installations simply ignore these UUIDs.
if command -v gnome-extensions >/dev/null 2>&1; then
  for extension in tiling-assistant@ubuntu.com ubuntu-appindicators@ubuntu.com ubuntu-dock@ubuntu.com ding@rastersoft.com; do
    gnome-extensions disable "$extension" >/dev/null 2>&1 || true
  done
fi

set_gsetting() {
  gsettings set "$1" "$2" "$3" >/dev/null 2>&1 || true
}

# Tactile: compact 4-column, 2-row keyboard layout.
set_gsetting org.gnome.shell.extensions.tactile col-0 1
set_gsetting org.gnome.shell.extensions.tactile col-1 2
set_gsetting org.gnome.shell.extensions.tactile col-2 1
set_gsetting org.gnome.shell.extensions.tactile col-3 0
set_gsetting org.gnome.shell.extensions.tactile row-0 1
set_gsetting org.gnome.shell.extensions.tactile row-1 1
set_gsetting org.gnome.shell.extensions.tactile gap-size 32

# Just Perfection and Blur my Shell.
set_gsetting org.gnome.shell.extensions.just-perfection animation 2
set_gsetting org.gnome.shell.extensions.just-perfection dash-app-running true
set_gsetting org.gnome.shell.extensions.just-perfection workspace true
set_gsetting org.gnome.shell.extensions.just-perfection workspace-popup false
set_gsetting org.gnome.shell.extensions.just-perfection clock-menu-position 1
set_gsetting org.gnome.shell.extensions.just-perfection clock-menu-position-offset 0
set_gsetting org.gnome.shell.extensions.blur-my-shell.overview blur true
set_gsetting org.gnome.shell.extensions.blur-my-shell.overview sigma 36
set_gsetting org.gnome.shell.extensions.blur-my-shell.panel blur true
set_gsetting org.gnome.shell.extensions.blur-my-shell.panel sigma 36
set_gsetting org.gnome.shell.extensions.blur-my-shell.panel brightness 0.82
set_gsetting org.gnome.shell.extensions.blur-my-shell.panel static-blur true
set_gsetting org.gnome.shell.extensions.blur-my-shell.dash-to-dock blur true
set_gsetting org.gnome.shell.extensions.blur-my-shell.dash-to-dock brightness 0.7
set_gsetting org.gnome.shell.extensions.blur-my-shell.dash-to-dock sigma 30
set_gsetting org.gnome.shell.extensions.blur-my-shell.dash-to-dock static-blur true
set_gsetting org.gnome.shell.extensions.blur-my-shell.dash-to-dock override-background true

# Space Bar and TopHat.
set_gsetting org.gnome.shell.extensions.space-bar.behavior smart-workspace-names false
set_gsetting org.gnome.shell.extensions.space-bar.shortcuts enable-activate-workspace-shortcuts false
set_gsetting org.gnome.shell.extensions.space-bar.shortcuts enable-move-to-workspace-shortcuts true
set_gsetting org.gnome.shell.extensions.space-bar.shortcuts open-menu "@as []"
set_gsetting org.gnome.shell.extensions.tophat show-icons false
set_gsetting org.gnome.shell.extensions.tophat show-cpu false
set_gsetting org.gnome.shell.extensions.tophat show-disk false
set_gsetting org.gnome.shell.extensions.tophat show-mem false
set_gsetting org.gnome.shell.extensions.tophat show-fs false
set_gsetting org.gnome.shell.extensions.tophat network-usage-unit bits

# Search Light owns Super+Space. Ulauncher is assigned Super+Shift+Space in
# set-gnome-hotkeys.sh, avoiding a race between the two launchers.
set_gsetting org.gnome.shell.extensions.search-light shortcut-key "['<Super>space']"
set_gsetting org.gnome.shell.extensions.spotlight shortcut-key "['<Super>space']"
set_gsetting org.gnome.shell.extensions.superbar shortcut-key "['<Super>space']"
set_gsetting org.gnome.shell.extensions.com.github.hermes83.compiz-windows-effect preset P
set_gsetting org.gnome.shell.extensions.com.github.hermes83.compiz-alike-magic-lamp-effect effect default
set_gsetting org.gnome.shell.extensions.com.github.hermes83.compiz-alike-magic-lamp-effect duration 400
set_gsetting org.gnome.shell.extensions.wiggly hide-cursor true
set_gsetting org.gnome.shell.extensions.wiggly cursor-size 96
set_gsetting org.gnome.shell.extensions.alphabetical-app-grid folder-order-position end
set_gsetting org.gnome.shell.extensions.dash-to-panel panel-position BOTTOM
set_gsetting org.gnome.shell.extensions.dash-to-panel panel-size 32
set_gsetting org.gnome.shell.extensions.dash-to-panel panel-length 100
set_gsetting org.gnome.shell.extensions.dash-to-panel intellihide false
set_gsetting org.gnome.shell.extensions.dash-to-panel show-appmenu false
set_gsetting org.gnome.shell.extensions.dash-to-panel show-apps-icon true
set_gsetting org.gnome.shell.extensions.dash-to-dock dock-position BOTTOM
set_gsetting org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 48
set_gsetting org.gnome.shell.extensions.dash-to-dock show-trash false
set_gsetting org.gnome.shell.extensions.dash-to-dock show-mounts false
set_gsetting org.gnome.shell.extensions.dash-to-dock autohide true
set_gsetting org.gnome.shell.extensions.dash-to-dock intellihide true
set_gsetting org.gnome.shell.extensions.dash-to-dock transparency-mode FIXED
