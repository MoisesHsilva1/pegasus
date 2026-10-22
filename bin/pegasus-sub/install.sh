#!/bin/bash

PEGASUS_PATH="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"
[ ! -d "$PEGASUS_PATH" ] && PEGASUS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CHOICES=(
  "Dev Editor        Install alternative programming editors"
  "Dev Language      Install programming language environment"
  "Dev Database      Install development database in Docker"
  "Geekbench         CPU benchmarking tool"
  "OBS Studio        Record screencasts with inputs from both display + webcam"
  "Spotify           Stream music from the world's most popular service"
  "Tailscale         Mesh VPN based on WireGuard and with Magic DNS"
  "> All             Re-run any of the default installers"
  "<< Back           "
)

CHOICE=$(gum choose "${CHOICES[@]}" --height 26 --header "Install application")

if [[ "$CHOICE" == "<< Back"* ]] || [[ -z "$CHOICE" ]]; then
  echo ""
elif [[ "$CHOICE" == "> All"* ]]; then
  INSTALLER_FILE=$(gum file $PEGASUS_PATH/install)

  [[ -n "$INSTALLER_FILE" ]] &&
    gum confirm "Run installer?" &&
    source $INSTALLER_FILE &&
    gum spin --spinner globe --title "Install completed!" -- sleep 3
else
  INSTALLER=$(echo "$CHOICE" | awk -F ' {2,}' '{print $1}' | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

  case "$INSTALLER" in
  "dev-editor") INSTALLER_FILE="$PEGASUS_PATH/bin/pegasus-sub/install-dev-editor.sh" ;;
  "dev-language") INSTALLER_FILE="$PEGASUS_PATH/install/terminal/select-dev-language.sh" ;;
  "dev-database") INSTALLER_FILE="$PEGASUS_PATH/install/terminal/select-dev-storage.sh" ;;
  "tailscale") INSTALLER_FILE="$PEGASUS_PATH/install/terminal/optional/app-tailscale.sh" ;;
  "geekbench") INSTALLER_FILE="$PEGASUS_PATH/install/terminal/optional/app-geekbench.sh" ;;
  *) INSTALLER_FILE="$PEGASUS_PATH/install/desktop/optional/app-$INSTALLER.sh" ;;
  esac

  [ -f "$INSTALLER_FILE" ] && source $INSTALLER_FILE && gum spin --spinner globe --title "Install completed!" -- sleep 3
fi

clear
source "$PEGASUS_PATH/bin/pegasus"
