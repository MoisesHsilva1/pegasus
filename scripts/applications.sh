#!/bin/bash

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEGASUS_DIR="${PEGASUS_DIR:-$(cd "$_SCRIPT_DIR/.." && pwd)}"
source "$PEGASUS_DIR/scripts/ui.sh"

install_applications() {
  print_section "Installing Desktop Applications & Flatpaks"

  # Core DNF Applications (Alacritty, GNOME Sushi, GNOME Tweaks, wl-clipboard, Ulauncher)
  step_info "Installing core desktop packages (Alacritty, GNOME Sushi, GNOME Tweaks, wl-clipboard, Ulauncher)..."
  [ -f "$PEGASUS_DIR/install/desktop/app-gnome-sushi.sh" ] && source "$PEGASUS_DIR/install/desktop/app-gnome-sushi.sh"
  [ -f "$PEGASUS_DIR/install/desktop/app-gnome-tweak-tool.sh" ] && source "$PEGASUS_DIR/install/desktop/app-gnome-tweak-tool.sh"
  [ -f "$PEGASUS_DIR/install/desktop/app-wl-clipboard.sh" ] && source "$PEGASUS_DIR/install/desktop/app-wl-clipboard.sh"
  [ -f "$PEGASUS_DIR/install/desktop/ulauncher.sh" ] && source "$PEGASUS_DIR/install/desktop/ulauncher.sh"
  step_success "Core desktop applications installed"

  # Ensure Flatpak and Flathub are ready
  step_info "Configuring Flatpak and Flathub repository..."
  sudo dnf install -y --skip-unavailable --skip-broken flatpak gnome-software >/dev/null
  sudo flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo >/dev/null
  step_success "Flathub repository enabled"

  # Visual Studio Code
  step_info "Installing Visual Studio Code..."
  if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc 2>/dev/null
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
  fi
  sudo dnf install -y --skip-unavailable --skip-broken code >/dev/null
  mkdir -p ~/.config/Code/User
  [ -f "$PEGASUS_DIR/configs/vscode.json" ] && cp "$PEGASUS_DIR/configs/vscode.json" ~/.config/Code/User/settings.json 2>/dev/null || true
  code --install-extension cverlinden.cursor-dark >/dev/null 2>&1 || step_warn "VS Code theme extension could not be installed"
  step_success "Visual Studio Code installed and Cursor Dark theme configured"

  # LibreOffice
  step_info "Installing LibreOffice..."
  sudo dnf install -y --skip-unavailable --skip-broken libreoffice >/dev/null
  step_success "LibreOffice installed"

  # Flatpak Target Applications (Obsidian, DBeaver Community, Postman, IntelliJ IDEA Community)
  step_info "Installing development & productivity applications via Flathub..."

  step_info " -> Obsidian"
  flatpak install -y flathub md.obsidian.Obsidian >/dev/null

  step_info " -> DBeaver Community"
  flatpak install -y flathub io.dbeaver.DBeaverCommunity >/dev/null

  step_info " -> Postman"
  flatpak install -y flathub com.getpostman.Postman >/dev/null

  step_info " -> IntelliJ IDEA Community"
  flatpak install -y flathub com.jetbrains.IntelliJ-IDEA-Community >/dev/null

  step_success "Flathub applications installed"

  # Fonts Installation
  step_info "Installing Cascadia Mono Nerd Font and iA Writer Mono..."
  mkdir -p ~/.local/share/fonts
  cd /tmp
  wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip
  unzip -qo CascadiaMono.zip -d CascadiaFont
  cp CascadiaFont/*.ttf ~/.local/share/fonts/
  rm -rf CascadiaMono.zip CascadiaFont

  wget -q -O iafonts.zip https://github.com/iaolo/iA-Fonts/archive/refs/heads/master.zip
  unzip -qo iafonts.zip -d iaFonts
  cp iaFonts/iA-Fonts-master/iA\ Writer\ Mono/Static/iAWriterMonoS-*.ttf ~/.local/share/fonts/
  rm -rf iafonts.zip iaFonts
  fc-cache >/dev/null 2>&1
  cd - >/dev/null
  step_success "Fonts installed"
}

install_applications
