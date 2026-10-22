#!/bin/bash

# Ensure gum is available
if ! command -v gum >/dev/null 2>&1; then
  _DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  _ROOT="${PEGASUS_PATH:-$(cd "$_DIR/.." && pwd)}"
  [ -f "$_ROOT/install/terminal/required/app-gum.sh" ] && source "$_ROOT/install/terminal/required/app-gum.sh"
fi
if ! command -v gum >/dev/null 2>&1; then
  echo "Error: 'gum' is required for interactive choices but could not be found."
  exit 1
fi

# Only ask for default desktop app choices when running Gnome

if [[ "$XDG_CURRENT_DESKTOP" == *"GNOME"* ]]; then
  OPTIONAL_APPS=("Spotify" "OBS-Studio" "1Password" "Mainline-Kernels")
  DEFAULT_OPTIONAL_APPS="Spotify,OBS-Studio,1Password"
  export PEGASUS_FIRST_RUN_OPTIONAL_APPS=$(gum choose "${OPTIONAL_APPS[@]}" --no-limit --selected "$DEFAULT_OPTIONAL_APPS" --height 8 --header "Select optional apps" | tr ' ' '-')
  export OMAKUB_FIRST_RUN_OPTIONAL_APPS="$PEGASUS_FIRST_RUN_OPTIONAL_APPS"
fi

AVAILABLE_LANGUAGES=("Ruby on Rails" "Node.js" "Go" "PHP" "Python" "Elixir" "Rust" "Java")
SELECTED_LANGUAGES="Node.js,Python,Java"
export PEGASUS_FIRST_RUN_LANGUAGES=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --selected "$SELECTED_LANGUAGES" --height 10 --header "Select programming languages")
export OMAKUB_FIRST_RUN_LANGUAGES="$PEGASUS_FIRST_RUN_LANGUAGES"

# Databases are intentionally excluded from the initial installation. Use
# `pegasus install` -> Dev Database later when Docker is explicitly requested.
