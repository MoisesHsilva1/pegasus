#!/bin/bash

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEGASUS_DIR="${PEGASUS_DIR:-$(cd "$_SCRIPT_DIR/.." && pwd)}"
source "$PEGASUS_DIR/scripts/ui.sh"

setup_gnome() {
  print_section "Configuring GNOME Desktop Environment, Extensions & Ulauncher"

  # System Utilities & GNOME Tools
  step_info "Installing GNOME Tweaks, Extension Manager & wl-clipboard..."
  sudo dnf install -y --skip-unavailable --skip-broken gnome-tweaks gnome-shell-extension-manager wl-clipboard libgtop2-devel clutter >/dev/null 2>&1 || true
  pipx install gnome-extensions-cli --system-site-packages >/dev/null 2>&1 || true
  step_success "GNOME system tools installed"

  # Ulauncher Launcher & Dark Theme Configuration
  step_info "Configuring Ulauncher application launcher..."
  [ -f "$PEGASUS_DIR/install/desktop/ulauncher.sh" ] && source "$PEGASUS_DIR/install/desktop/ulauncher.sh"
  step_success "Ulauncher installed & configured with dark theme and autostart"

  # Desktop Launchers
  step_info "Generating desktop launchers (About, Activity, Basecamp, Docker, HEY, Neovim, Pegasus)..."
  mkdir -p ~/.local/share/applications
  [ -f "$PEGASUS_DIR/applications/About.sh" ] && source "$PEGASUS_DIR/applications/About.sh"
  [ -f "$PEGASUS_DIR/applications/Activity.sh" ] && source "$PEGASUS_DIR/applications/Activity.sh"
  [ -f "$PEGASUS_DIR/applications/Basecamp.sh" ] && source "$PEGASUS_DIR/applications/Basecamp.sh"
  [ -f "$PEGASUS_DIR/applications/Docker.sh" ] && source "$PEGASUS_DIR/applications/Docker.sh"
  [ -f "$PEGASUS_DIR/applications/HEY.sh" ] && source "$PEGASUS_DIR/applications/HEY.sh"
  [ -f "$PEGASUS_DIR/applications/Neovim.sh" ] && source "$PEGASUS_DIR/applications/Neovim.sh"
  [ -f "$PEGASUS_DIR/applications/Omakub.sh" ] && source "$PEGASUS_DIR/applications/Omakub.sh"
  [ -f "$PEGASUS_DIR/applications/pegasus.sh" ] && source "$PEGASUS_DIR/applications/pegasus.sh"
  [ -f "$PEGASUS_DIR/applications/Theme.sh" ] && source "$PEGASUS_DIR/applications/Theme.sh"
  step_success "Desktop launchers generated"

  # GNOME Extensions and portable visual assets
  step_info "Installing GNOME Shell extensions and visual assets..."
  [ -f "$PEGASUS_DIR/install/desktop/set-gnome-extensions.sh" ] && source "$PEGASUS_DIR/install/desktop/set-gnome-extensions.sh" >/dev/null 2>&1 || true
  [ -f "$PEGASUS_DIR/install/desktop/install-assets.sh" ] && source "$PEGASUS_DIR/install/desktop/install-assets.sh" >/dev/null 2>&1 || true
  step_success "GNOME Shell extensions installed"

  # Apply GNOME Hotkeys & Settings
  step_info "Configuring GNOME keybindings and interface preferences..."
  [ -f "$PEGASUS_DIR/install/desktop/set-gnome-hotkeys.sh" ] && source "$PEGASUS_DIR/install/desktop/set-gnome-hotkeys.sh" >/dev/null 2>&1 || true
  [ -f "$PEGASUS_DIR/install/desktop/set-gnome-settings.sh" ] && source "$PEGASUS_DIR/install/desktop/set-gnome-settings.sh" >/dev/null 2>&1 || true
  [ -f "$PEGASUS_DIR/install/desktop/set-app-grid.sh" ] && source "$PEGASUS_DIR/install/desktop/set-app-grid.sh" >/dev/null 2>&1 || true
  [ -f "$PEGASUS_DIR/install/desktop/set-dock.sh" ] && source "$PEGASUS_DIR/install/desktop/set-dock.sh" >/dev/null 2>&1 || true
  step_success "GNOME preferences & dock launchers configured"

  step_success "GNOME extensions, preferences, and visual assets configured"
}

setup_gnome
