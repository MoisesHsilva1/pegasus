#!/bin/bash

PEGASUS_PATH="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"
[ ! -d "$PEGASUS_PATH" ] && PEGASUS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CURRENT_THEME_FILE="$HOME/.config/pegasus/current_theme"
if [ -f "${PEGASUS_PATH:-}/scripts/installer-state.sh" ]; then
  source "$PEGASUS_PATH/scripts/installer-state.sh"
  installer_manifest_init 2>/dev/null || true
fi
trap 'stty echo 2>/dev/null; tput cnorm 2>/dev/null' EXIT INT TERM

get_current_theme() {
  if [ -f "$CURRENT_THEME_FILE" ]; then
    cat "$CURRENT_THEME_FILE"
  else
    echo "tokyo-night"
  fi
}

get_available_themes() {
  local themes=()
  for dir in "$PEGASUS_PATH"/themes/*; do
    if [ -d "$dir" ]; then
      themes+=("$(basename "$dir")")
    fi
  done
  echo "${themes[@]}"
}

format_title() {
  local slug="$1"
  echo "$slug" | tr '-' ' ' | sed -e 's/\b\(.\)/\u\1/g'
}

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g'
}

resolve_theme_slug() {
  local input="$1"
  local themes=($(get_available_themes))

  # Check if numeric input
  if [[ "$input" =~ ^[0-9]+$ ]]; then
    local idx=$((input - 1))
    if [ $idx -ge 0 ] && [ $idx -lt ${#themes[@]} ]; then
      echo "${themes[$idx]}"
      return 0
    fi
  fi

  local target_slug=$(slugify "$input")
  for t in "${themes[@]}"; do
    if [ "$t" = "$target_slug" ] || [ "$(format_title "$t" | tr '[:upper:]' '[:lower:]')" = "$(echo "$input" | tr '[:upper:]' '[:lower:]')" ]; then
      echo "$t"
      return 0
    fi
  done

  echo "$target_slug"
}

apply_component() {
  local label="$1"
  local cmd="$2"
  eval "$cmd" >/dev/null 2>&1
  local status=$?
  if [ $status -eq 0 ]; then
    echo "✓ $label updated"
  else
    echo "! $label (skipped / warning)"
  fi
}

apply_theme() {
  local raw_input="$1"
  local THEME=$(resolve_theme_slug "$raw_input")
  local TITLE=$(format_title "$THEME")

  if [ ! -d "$PEGASUS_PATH/themes/$THEME" ]; then
    echo "Error: Theme '$raw_input' not found in $PEGASUS_PATH/themes/" >&2
    return 1
  fi

  echo ""
  echo "Applying $TITLE theme..."
  echo ""

  # Save active theme state and preserve the original managed values once.
  mkdir -p "$HOME/.config/pegasus"
  installer_manifest_track_file "$CURRENT_THEME_FILE" 2>/dev/null || true
  for theme_file in "$HOME/.config/alacritty/theme.toml" "$HOME/.config/zellij/config.kdl" "$HOME/.config/btop/btop.conf"; do
    installer_manifest_track_file "$theme_file" 2>/dev/null || true
  done
  installer_manifest_track_setting org.gnome.desktop.interface color-scheme 2>/dev/null || true
  echo "$THEME" > "$CURRENT_THEME_FILE"
  if [ -n "${PEGASUS_MANIFEST_FILE:-}" ] && [ -f "$PEGASUS_MANIFEST_FILE" ]; then
    installer_manifest_update --arg theme "$THEME" 'if .themes.original == null then .themes.original=$theme else . end | .themes.current=$theme' 2>/dev/null || true
  fi

  # 1. GNOME Desktop & System Colors & Wallpaper
  if [ -f "$PEGASUS_PATH/themes/$THEME/gnome.sh" ]; then
    apply_component "System theme" "source '$PEGASUS_PATH/themes/$THEME/gnome.sh'"
    apply_component "GNOME colors" "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
    apply_component "Wallpaper" "[ -f '$PEGASUS_PATH/themes/set-gnome-theme.sh' ] && source '$PEGASUS_PATH/themes/set-gnome-theme.sh'"
  else
    apply_component "System theme" "gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'"
    apply_component "GNOME colors" "true"
    apply_component "Wallpaper" "true"
  fi

  # 2. Alacritty
  if [ -d "$HOME/.config/alacritty" ]; then
    apply_component "Alacritty" "[ -f '$PEGASUS_PATH/themes/$THEME/alacritty.toml' ] && cp '$PEGASUS_PATH/themes/$THEME/alacritty.toml' ~/.config/alacritty/theme.toml"
  fi

  # 3. Zellij
  if [ -d "$HOME/.config/zellij" ]; then
    mkdir -p ~/.config/zellij/themes
    apply_component "Zellij" "[ -f '$PEGASUS_PATH/themes/$THEME/zellij.kdl' ] && cp '$PEGASUS_PATH/themes/$THEME/zellij.kdl' ~/.config/zellij/themes/$THEME.kdl && [ -f ~/.config/zellij/config.kdl ] && sed -i 's/theme \".*\"/theme \"$THEME\"/g' ~/.config/zellij/config.kdl"
  fi

  # 4. Visual Studio Code
  if [ -f "$PEGASUS_PATH/themes/$THEME/vscode.sh" ]; then
    apply_component "VS Code" "source '$PEGASUS_PATH/themes/$THEME/vscode.sh'"
  fi

  # 6. btop
  if [ -d "$HOME/.config/btop" ]; then
    apply_component "btop" "[ -f '$PEGASUS_PATH/themes/$THEME/btop.theme' ] && cp '$PEGASUS_PATH/themes/$THEME/btop.theme' ~/.config/btop/themes/$THEME.theme && [ -f ~/.config/btop/btop.conf ] && sed -i 's/color_theme = \".*\"/color_theme = \"$THEME\"/g' ~/.config/btop/btop.conf"
  fi

  echo ""
  echo "Theme applied successfully."
  installer_manifest_record_setting org.gnome.desktop.interface color-scheme 2>/dev/null || true
  installer_manifest_refresh_files 2>/dev/null || true
  echo ""
  return 0
}

# Router for sub-commands: list, current, apply
case "${1:-}" in
  "list")
    echo "Available themes:"
    echo ""
    i=1
    for t in $(get_available_themes); do
      echo "  $i. $(format_title "$t")"
      ((i++))
    done
    echo ""
    exit 0
    ;;
  "current")
    curr=$(get_current_theme)
    echo "Currently active theme: $(format_title "$curr") ($curr)"
    exit 0
    ;;
  "apply")
    if [ -z "${2:-}" ]; then
      echo "Usage: pegasus theme apply <theme-name|number>" >&2
      exit 1
    fi
    apply_theme "$2"
    exit 0
    ;;
esac

# Interactive TUI Menu Mode (pegasus theme with no args)
echo "Pegasus Theme Manager"
echo ""
echo "Available themes:"
echo ""

THEME_SLUGS=($(get_available_themes))
THEME_TITLES=()
for slug in "${THEME_SLUGS[@]}"; do
  THEME_TITLES+=("$(format_title "$slug")")
done

if command -v gum >/dev/null 2>&1; then
  SELECTED_TITLE=$(gum choose "${THEME_TITLES[@]}" "<< Cancel" --header "↑ ↓ Navigate  |  Enter Apply  |  ESC Cancel" --height 14)
  if [ -n "$SELECTED_TITLE" ] && [ "$SELECTED_TITLE" != "<< Cancel" ]; then
    SELECTED_SLUG=$(slugify "$SELECTED_TITLE")
    apply_theme "$SELECTED_SLUG"
  fi
else
  i=1
  for title in "${THEME_TITLES[@]}"; do
    echo "$i) $title"
    ((i++))
  done
  echo ""
  read -p "Select a theme: " CHOICE
  if [ -n "$CHOICE" ]; then
    apply_theme "$CHOICE"
  fi
fi

if [ -n "$PEGASUS_CLI_MENU" ]; then
  source "$PEGASUS_PATH/bin/pegasus-sub/menu.sh"
fi
