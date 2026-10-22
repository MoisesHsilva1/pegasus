#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PEGASUS_PATH="${PEGASUS_PATH:-$SCRIPT_DIR}"
source "$SCRIPT_DIR/scripts/ui.sh"

print_banner
print_section "Pegasus Uninstaller"

step_warn "This uninstaller will remove Pegasus desktop launchers, dotfile aliases, and desktop configurations."

read -p "Are you sure you want to proceed with uninstallation? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Uninstallation cancelled."
  exit 0
fi

step_info "Removing desktop launchers..."
rm -f ~/.local/share/applications/Pegasus.desktop ~/.local/share/applications/PegasusTheme.desktop ~/.local/share/applications/Docker.desktop ~/.local/share/applications/About.desktop ~/.local/share/applications/Activity.desktop ~/.local/share/applications/Basecamp.desktop ~/.local/share/applications/HEY.desktop ~/.local/share/applications/Omakub.desktop 2>/dev/null || true

step_info "Removing Pegasus binaries and symlinks..."
rm -f ~/.local/bin/pegasus ~/.local/bin/omakub 2>/dev/null || true
rm -rf ~/.local/share/pegasus ~/.local/share/omakub 2>/dev/null || true

step_success "Pegasus uninstalled. Reboot recommended to reset desktop settings."
