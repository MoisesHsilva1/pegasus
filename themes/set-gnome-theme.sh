#!/bin/bash

PEGASUS_PATH="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"

gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface accent-color "${PEGASUS_THEME_COLOR:-blue}" 2>/dev/null || true

THEME_BG="${PEGASUS_THEME_BACKGROUND:-}"
BACKGROUND_ORG_PATH="$PEGASUS_PATH/themes/$THEME_BG"
BACKGROUND_DEST_DIR="$HOME/.local/share/backgrounds"
BACKGROUND_DEST_PATH="$BACKGROUND_DEST_DIR/$(echo $THEME_BG | tr '/' '-')"

if [ ! -d "$BACKGROUND_DEST_DIR" ]; then mkdir -p "$BACKGROUND_DEST_DIR"; fi

[ -f "$BACKGROUND_ORG_PATH" ] && [ ! -f "$BACKGROUND_DEST_PATH" ] && cp "$BACKGROUND_ORG_PATH" "$BACKGROUND_DEST_PATH"
if [ -f "$BACKGROUND_DEST_PATH" ]; then
  gsettings set org.gnome.desktop.background picture-uri "file://$BACKGROUND_DEST_PATH" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-uri-dark "file://$BACKGROUND_DEST_PATH" 2>/dev/null || true
  gsettings set org.gnome.desktop.background picture-options 'zoom' 2>/dev/null || true
fi
