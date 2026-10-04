#!/bin/bash

# Ulauncher Launcher Setup & Dark Theme Configuration for Pegasus Linux

# 1. Install Ulauncher via DNF if missing
if ! command -v ulauncher >/dev/null 2>&1; then
  sudo dnf install -y --skip-unavailable ulauncher >/dev/null 2>&1 || true
fi

# 2. Configure Autostart
mkdir -p ~/.config/autostart
cat <<EOF >~/.config/autostart/ulauncher.desktop
[Desktop Entry]
Type=Application
Name=Ulauncher
Comment=Application launcher for Linux
Exec=ulauncher --hide-window
Icon=ulauncher
Terminal=false
Categories=Utility;
X-GNOME-Autostart-enabled=true
EOF
chmod +x ~/.config/autostart/ulauncher.desktop 2>/dev/null || true

# 3. Configure Ulauncher Settings. Search Light owns Super+Space; Ulauncher
# uses Super+Shift+Space to keep the two launchers deterministic.
mkdir -p ~/.config/ulauncher
if [ -f "$PEGASUS_PATH/configs/ulauncher.json" ]; then
  cp "$PEGASUS_PATH/configs/ulauncher.json" ~/.config/ulauncher/settings.json 2>/dev/null || true
else
  cat <<EOF >~/.config/ulauncher/settings.json
{
  "blacklisted-desktop-files": [],
  "clear-previous-query": true,
  "disable-app-indicators": false,
  "grab-mouse-pointer": false,
  "hotkey-show-app": "<Super><Shift>space",
  "show-indicator-icon": true,
  "show-recent-apps": "5",
  "theme-name": "dark"
}
EOF
fi

# 4. Start Ulauncher in background if in GUI session
if [ -n "$DISPLAY" ] || [ -n "$WAYLAND_DISPLAY" ]; then
  ulauncher --hide-window >/dev/null 2>&1 &
fi
