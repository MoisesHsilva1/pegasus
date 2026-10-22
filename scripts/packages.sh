#!/bin/bash

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEGASUS_DIR="${PEGASUS_DIR:-$(cd "$_SCRIPT_DIR/.." && pwd)}"
source "$PEGASUS_DIR/scripts/ui.sh"

install_packages() {
  print_section "Installing Development Libraries & System Utilities"

  # System Upgrade & Core Libraries
  step_info "Updating package repositories..."
  if ! sudo dnf check-update >/dev/null 2>&1; then
    step_info "DNF metadata check completed (updates may be available)"
  fi
  step_info "Installing core build tools and development headers via DNF..."
  sudo dnf install -y --skip-unavailable --skip-broken \
    @development-tools pkgconfig autoconf bison clang rustc pipx \
    openssl-devel readline-devel zlib-devel libyaml-devel ncurses-devel libffi-devel gdbm-devel jemalloc-devel \
    vips-devel ImageMagick ImageMagick-devel mupdf mupdf-devel \
    sqlite sqlite-devel mariadb-devel postgresql >/dev/null
  step_success "Core development libraries installed"

  step_info "Installing CLI utilities..."
  sudo dnf install -y --skip-unavailable --skip-broken \
    fzf ripgrep bat eza zoxide plocate httpd-tools fd-find btop fastfetch gh luarocks tree-sitter-cli >/dev/null
  step_success "CLI utilities installed"

  # The initial workstation profile deliberately does not install Neovim, LazyVim,
  # Docker or database containers. They remain available through the manual menu.
  step_info "Skipping Neovim, LazyVim, Docker and database containers in the base profile"

  # Zellij Multiplexer
  step_info "Installing Zellij multiplexer..."
  cd /tmp
  wget -qO zellij.tar.gz "https://github.com/zellij-org/zellij/releases/latest/download/zellij-x86_64-unknown-linux-musl.tar.gz"
  tar -xf zellij.tar.gz zellij
  sudo install zellij /usr/local/bin
  rm -f zellij.tar.gz zellij
  mkdir -p ~/.config/zellij/themes
  [ -f "$PEGASUS_DIR/configs/zellij.kdl" ] && [ ! -f "$HOME/.config/zellij/config.kdl" ] && cp "$PEGASUS_DIR/configs/zellij.kdl" ~/.config/zellij/config.kdl
  cd - >/dev/null
  step_success "Zellij installed"

  # Mise Version Manager
  step_info "Installing Mise runtime version manager..."
  if [ -f "$PEGASUS_DIR/install/terminal/required/app-mise.sh" ]; then
    source "$PEGASUS_DIR/install/terminal/required/app-mise.sh"
  fi
  step_success "Mise version manager installed"

}

install_packages
