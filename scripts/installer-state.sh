#!/bin/bash

# Persistent, credential-free installer state and log helpers.
set -u

PEGASUS_STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pegasus"
PEGASUS_STATE_FILE="$PEGASUS_STATE_DIR/installer-state.json"
PEGASUS_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/pegasus"
PEGASUS_LOG_FILE="$PEGASUS_LOG_DIR/install.log"
PEGASUS_INSTALLER_VERSION="2"
export PEGASUS_STATE_FILE PEGASUS_LOG_FILE PEGASUS_INSTALLER_VERSION

installer_state_init() {
  mkdir -p "$PEGASUS_STATE_DIR" "$PEGASUS_LOG_DIR"
  if [ ! -s "$PEGASUS_STATE_FILE" ] || ! jq empty "$PEGASUS_STATE_FILE" >/dev/null 2>&1; then
    jq -n --arg version "$PEGASUS_INSTALLER_VERSION" \
      '{installer_version:$version, choices:{}, steps:{}, last_run:null}' > "$PEGASUS_STATE_FILE"
  fi
}

installer_state_update() {
  local filter="$1" tmp
  shift
  tmp="$(mktemp "${PEGASUS_STATE_FILE}.XXXXXX")"
  jq "$filter" "$@" "$PEGASUS_STATE_FILE" > "$tmp" && mv "$tmp" "$PEGASUS_STATE_FILE"
  rm -f "$tmp"
}

installer_state_set_choice() {
  local key="$1" value="$2"
  installer_state_update --arg key "$key" --arg value "$value" \
    '.choices[$key]=$value | .last_run=(now | todateiso8601)'
}

installer_state_set_step() {
  local step="$1" status="$2" reason="${3:-}"
  installer_state_update --arg step "$step" --arg status "$status" --arg reason "$reason" \
    '.steps[$step]={status:$status,reason:$reason,updated_at:(now | todateiso8601)} | .last_run=(now | todateiso8601)'
}

installer_state_step_status() {
  jq -r --arg step "$1" '.steps[$step].status // "pending"' "$PEGASUS_STATE_FILE"
}

installer_log_start() {
  mkdir -p "$PEGASUS_LOG_DIR"
  exec > >(tee -a "$PEGASUS_LOG_FILE") 2>&1
  echo "[$(date --iso-8601=seconds)] Pegasus installer started (version $PEGASUS_INSTALLER_VERSION)"
}
``