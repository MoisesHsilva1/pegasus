#!/bin/bash

PEGASUS_PATH="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"
[ ! -d "$PEGASUS_PATH" ] && PEGASUS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

export PEGASUS_CLI_MENU=1
trap 'stty echo 2>/dev/null; tput cnorm 2>/dev/null' EXIT INT TERM

clear
source "$PEGASUS_PATH/bin/pegasus-sub/header.sh" 2>/dev/null || true

echo "Pegasus Control Center"
echo ""
echo "Select an option:"
echo ""

MENU_OPTIONS=(
  "Theme          Change visual workstation theme"
  "Font           Change programming font & font size"
  "Install        Review or resume the Pegasus installation"
  "Uninstall      Remove installed applications & launchers"
  "Update         Upgrade Pegasus and managed packages"
  "Diagnostics    Run system health check (doctor)"
  "Manual         Open project documentation"
  "Quit           Exit Pegasus Control Center"
)

if [ $# -eq 0 ]; then
  CHOICE=$(gum choose "${MENU_OPTIONS[@]}" --height 12 --header "↑ ↓ Navigate  |  Enter Select  |  ESC Exit")
  SUB=$(echo "$CHOICE" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
else
  SUB=$1
fi

if [ -n "$SUB" ] && [ "$SUB" != "quit" ]; then
  case "$SUB" in
    "theme") source "$PEGASUS_PATH/bin/pegasus-sub/theme.sh" ;;
    "font") source "$PEGASUS_PATH/bin/pegasus-sub/font.sh" ;;
    "install") source "$PEGASUS_PATH/bin/pegasus-sub/install.sh" ;;
    "uninstall") source "$PEGASUS_PATH/uninstall.sh" ;;
    "update") source "$PEGASUS_PATH/update.sh" ;;
    "diagnostics"|"doctor") source "$PEGASUS_PATH/scripts/doctor.sh" ;;
    "manual") source "$PEGASUS_PATH/bin/pegasus-sub/manual.sh" ;;
    *)
      if [ -f "$PEGASUS_PATH/bin/pegasus-sub/$SUB.sh" ]; then
        source "$PEGASUS_PATH/bin/pegasus-sub/$SUB.sh"
      fi
      ;;
  esac
fi
