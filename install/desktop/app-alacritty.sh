#!/bin/bash

set -u

if ! command -v alacritty >/dev/null 2>&1; then
  sudo dnf install -y --skip-unavailable alacritty >/dev/null || exit 1
fi

# Copy default Alacritty configuration
mkdir -p ~/.config/alacritty
PEGASUS_DIR="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"
[ ! -d "$PEGASUS_DIR" ] && PEGASUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

apply_style=0
if find "$HOME/.config/alacritty" -maxdepth 1 -type f -print -quit | grep -q .; then
  if [ "${PEGASUS_INSTALLER_YES:-0}" -eq 1 ]; then
    apply_style=0
  elif command -v gum >/dev/null 2>&1 && gum confirm "Apply Pegasus Alacritty style? Existing files will be backed up."; then
    apply_style=1
  else
    step_warn "Existing Alacritty configuration preserved"
  fi
else
  apply_style=1
fi

if [ -f "${PEGASUS_STATE_FILE:-}" ] && declare -F installer_state_set_choice >/dev/null 2>&1; then
  if [ "$apply_style" -eq 1 ]; then
    installer_state_set_choice alacritty_style "applied"
  else
    installer_state_set_choice alacritty_style "preserved"
  fi
fi

if [ "$apply_style" -eq 1 ] && [ -d "$PEGASUS_DIR/configs/alacritty" ]; then
  backup_dir="$HOME/.config/alacritty.backup.$(date +%Y%m%d-%H%M%S)"
  if find "$HOME/.config/alacritty" -maxdepth 1 -type f -print -quit | grep -q .; then
    mkdir -p "$backup_dir"
    cp -a "$HOME/.config/alacritty/." "$backup_dir/"
    step_info "Backed up existing Alacritty files to $backup_dir"
  fi
  cp -a "$PEGASUS_DIR/configs/alacritty/." "$HOME/.config/alacritty/"
  if [ -f "$PEGASUS_DIR/themes/tokyo-night/alacritty.toml" ]; then
    cp "$PEGASUS_DIR/themes/tokyo-night/alacritty.toml" "$HOME/.config/alacritty/theme.toml"
  fi
fi

# Initialize default theme and font if missing
if [ ! -f ~/.config/alacritty/theme.toml ] && [ -f "$PEGASUS_DIR/themes/tokyo-night/alacritty.toml" ]; then
  cp "$PEGASUS_DIR/themes/tokyo-night/alacritty.toml" ~/.config/alacritty/theme.toml
fi

if [ ! -f ~/.config/alacritty/font.toml ] && [ -f ~/.config/alacritty/fonts/CaskaydiaMono.toml ]; then
  cp ~/.config/alacritty/fonts/CaskaydiaMono.toml ~/.config/alacritty/font.toml
fi

gsettings set org.gnome.desktop.default-applications.terminal exec alacritty
gsettings set org.gnome.desktop.default-applications.terminal exec-arg -e
