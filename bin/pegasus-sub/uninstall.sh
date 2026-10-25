#!/bin/bash

if [ -x "$HOME/.local/bin/pegasus-uninstall" ]; then
  exec "$HOME/.local/bin/pegasus-uninstall" "$@"
fi
PEGASUS_PATH="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"
[ ! -d "$PEGASUS_PATH" ] && PEGASUS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

UNINSTALLER=$(gum file "$PEGASUS_PATH/uninstall" --height 26)
[ -n "$UNINSTALLER" ] && gum confirm "Run uninstaller?" && source "$UNINSTALLER" && gum spin --spinner globe --title "Uninstall completed!" -- sleep 3
clear
source "$PEGASUS_PATH/bin/pegasus"
