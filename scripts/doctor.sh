#!/bin/bash

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEGASUS_DIR="${PEGASUS_DIR:-$(cd "$_SCRIPT_DIR/.." && pwd)}"
source "$PEGASUS_DIR/scripts/ui.sh"

run_doctor() {
  print_banner
  print_section "Pegasus System Diagnostic (Doctor)"

  # 1. OS Check
  if [ -f /etc/os-release ]; then
    source /etc/os-release
    if [ "$ID" = "fedora" ]; then
      step_success "OS: Fedora Linux ($NAME $VERSION_ID)"
    else
      step_error "OS: Non-Fedora distribution detected ($ID)"
    fi
  else
    step_error "OS: /etc/os-release not found"
  fi

  # 2. Package Managers & UI Tools
  if command -v dnf >/dev/null 2>&1; then
    step_success "Package Manager: dnf available"
  else
    step_error "Package Manager: dnf missing"
  fi

  if command -v gum >/dev/null 2>&1; then
    step_success "UI Engine: gum available ($(gum --version 2>/dev/null | head -n 1))"
  else
    step_error "UI Engine: gum missing"
  fi

  if command -v flatpak >/dev/null 2>&1; then
    if flatpak remotes | grep -q "flathub"; then
      step_success "Flatpak: Flathub remote registered"
    else
      step_warn "Flatpak: Installed but Flathub remote missing"
    fi
  else
    step_error "Flatpak: Not installed"
  fi

  # Docker and Neovim are optional manual installs, not base-profile health checks.
  # 3. Core Development Editors
  if command -v code >/dev/null 2>&1; then
    step_success "Visual Studio Code: $(code --version | head -n 1 2>/dev/null || echo "Installed")"
  else
    step_warn "Visual Studio Code: Not installed"
  fi

  if command -v mise >/dev/null 2>&1; then
    step_success "Mise Version Manager: $(mise --version 2>/dev/null | head -n 1)"
  else
    step_warn "Mise Version Manager: Not installed"
  fi

  # 4. Installed Target Flatpaks
  print_section "Target Flatpak Applications Status"
  local flatpaks=(
    "md.obsidian.Obsidian:Obsidian"
    "org.signal.Signal:Signal Desktop"
    "com.spotify.Client:Spotify"
    "org.videolan.VLC:VLC Media Player"
    "com.obsproject.Studio:OBS Studio"
    "org.gimp.GIMP:GIMP"
    "io.dbeaver.DBeaverCommunity:DBeaver Community"
    "com.getpostman.Postman:Postman"
    "com.jetbrains.IntelliJ-IDEA-Community:IntelliJ IDEA Community"
  )

  for entry in "${flatpaks[@]}"; do
    local app_id="${entry%%:*}"
    local app_name="${entry##*:}"
    if flatpak list --app | grep -q "$app_id"; then
      step_success "$app_name ($app_id)"
    else
      step_warn "$app_name not installed"
    fi
  done

  echo ""
}

run_doctor
