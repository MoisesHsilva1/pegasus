#!/bin/bash

# Center new windows in the middle of the screen
gsettings set org.gnome.mutter center-new-windows true

# Set Cascadia Mono as the default monospace font
gsettings set org.gnome.desktop.interface monospace-font-name 'CaskaydiaMono Nerd Font 10'

# Reveal week numbers in the Gnome calendar
gsettings set org.gnome.desktop.calendar show-weekdate true

# Turn off ambient sensors for setting screen brightness (they rarely work well!)
gsettings set org.gnome.settings-daemon.plugins.power ambient-enabled false

# Portable visual defaults from the GNOME 50 profile.
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' 2>/dev/null || true
gsettings set org.gnome.desktop.interface accent-color 'green' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-theme 'macOS' 2>/dev/null || true
gsettings set org.gnome.desktop.interface cursor-size 24 2>/dev/null || true
gsettings set org.gnome.desktop.interface enable-animations true 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-format '24h' 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-date true 2>/dev/null || true
gsettings set org.gnome.desktop.interface clock-show-seconds false 2>/dev/null || true
