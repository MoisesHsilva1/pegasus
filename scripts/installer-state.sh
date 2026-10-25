#!/bin/bash

# Persistent, credential-free installer state and log helpers.
set -u

PEGASUS_STATE_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/pegasus"
PEGASUS_STATE_FILE="$PEGASUS_STATE_DIR/installer-state.json"
PEGASUS_LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/pegasus"
PEGASUS_LOG_FILE="$PEGASUS_LOG_DIR/install.log"
PEGASUS_RECOVERY_DIR="$PEGASUS_LOG_DIR/recovery"
PEGASUS_MANIFEST_FILE="$PEGASUS_RECOVERY_DIR/manifest.json"
PEGASUS_BACKUP_DIR="$PEGASUS_RECOVERY_DIR/backups"
PEGASUS_INSTALLER_VERSION="2"
export PEGASUS_STATE_FILE PEGASUS_LOG_FILE PEGASUS_RECOVERY_DIR PEGASUS_MANIFEST_FILE PEGASUS_BACKUP_DIR PEGASUS_INSTALLER_VERSION

installer_state_init() {
  mkdir -p "$PEGASUS_STATE_DIR" "$PEGASUS_LOG_DIR"
  if [ ! -s "$PEGASUS_STATE_FILE" ] || ! jq empty "$PEGASUS_STATE_FILE" >/dev/null 2>&1; then
    jq -n --arg version "$PEGASUS_INSTALLER_VERSION" \
      '{installer_version:$version, choices:{}, steps:{}, last_run:null}' > "$PEGASUS_STATE_FILE"
  fi
  installer_manifest_init
}

installer_manifest_init() {
  mkdir -p "$PEGASUS_RECOVERY_DIR" "$PEGASUS_BACKUP_DIR"
  if [ ! -s "$PEGASUS_MANIFEST_FILE" ] || ! jq empty "$PEGASUS_MANIFEST_FILE" >/dev/null 2>&1; then
    jq -n --arg version "$PEGASUS_INSTALLER_VERSION" --arg root "${PEGASUS_DIR:-}" \
      '{schema_version:1, installer_version:$version, pegasus_root:$root, created_at:(now|todateiso8601), updated_at:null, files:[], directories:[], symlinks:[], settings:[], packages:{dnf:[],flatpak:[]}, repositories:[], services:[], extensions:[], backups:[], themes:{original:null,current:null}, snapshots:{}}' > "$PEGASUS_MANIFEST_FILE"
  fi
}

installer_manifest_update() {
  local argc filter tmp
  argc="$#"
  filter="${!argc}"
  local -a jq_args=("${@:1:argc-1}")
  tmp="$(mktemp "${PEGASUS_MANIFEST_FILE}.XXXXXX")"
  if jq "${jq_args[@]}" "$filter | .updated_at=(now|todateiso8601)" "$PEGASUS_MANIFEST_FILE" > "$tmp"; then
    mv "$tmp" "$PEGASUS_MANIFEST_FILE"
  else
    rm -f "$tmp"
    return 1
  fi
}

installer_manifest_backup() {
  local path="$1" key backup
  [ -e "$path" ] || [ -L "$path" ] || return 0
  key="$(printf '%s' "$path" | sha256sum | cut -d' ' -f1)"
  backup="$PEGASUS_BACKUP_DIR/$key"
  if [ ! -e "$backup" ] && [ ! -L "$backup" ]; then
    if [ -d "$path" ] && [ ! -L "$path" ]; then cp -a "$path" "$backup"; else cp -a "$path" "$backup"; fi
  fi
  printf '%s\n' "$backup"
}

installer_manifest_track_file() {
  local path="$1" original backup hash type
  [ -n "$path" ] || return 0
  if jq -e --arg path "$path" '.files[]? | select(.path==$path)' "$PEGASUS_MANIFEST_FILE" >/dev/null 2>&1; then return 0; fi
  original=0; backup=""; hash=""; type="missing"
  if [ -L "$path" ]; then type=symlink; original=1; backup="$(installer_manifest_backup "$path")"; hash="$(readlink "$path")"
  elif [ -f "$path" ]; then type=file; original=1; backup="$(installer_manifest_backup "$path")"; hash="$(sha256sum "$path" | cut -d' ' -f1)"
  elif [ -d "$path" ]; then type=directory; original=1; backup="$(installer_manifest_backup "$path")"
  fi
  local original_json=false; [ "$original" -eq 1 ] && original_json=true
  installer_manifest_update --arg path "$path" --arg type "$type" --arg backup "$backup" --arg hash "$hash" --argjson original "$original_json" \
    '.files += [{path:$path,type:$type,original:$original,backup:(if $backup=="" then null else $backup end),original_hash:(if $hash=="" then null else $hash end),managed_hash:null,status:"tracked"}]'
}

installer_manifest_track_setting() {
  local schema="$1" key="$2" value
  command -v gsettings >/dev/null 2>&1 || return 0
  value="$(gsettings get "$schema" "$key" 2>/dev/null)" || return 0
  if ! jq -e --arg schema "$schema" --arg key "$key" '.settings[]? | select(.schema==$schema and .key==$key)' "$PEGASUS_MANIFEST_FILE" >/dev/null 2>&1; then
    installer_manifest_update --arg schema "$schema" --arg key "$key" --arg value "$value" \
      '.settings += [{schema:$schema,key:$key,original:$value,last_applied:null,status:"tracked"}]'
  fi
}

installer_manifest_record_setting() {
  local schema="$1" key="$2" value
  command -v gsettings >/dev/null 2>&1 || return 0
  value="$(gsettings get "$schema" "$key" 2>/dev/null)" || return 0
  if jq -e --arg schema "$schema" --arg key "$key" '.settings[]? | select(.schema==$schema and .key==$key)' "$PEGASUS_MANIFEST_FILE" >/dev/null 2>&1; then
    installer_manifest_update --arg schema "$schema" --arg key "$key" --arg value "$value" \
      '(.settings[] | select(.schema==$schema and .key==$key) | .last_applied)=$value'
  fi
}

installer_manifest_snapshot_packages() {
  local before_dnf before_flatpak
  before_dnf="$(mktemp "$PEGASUS_RECOVERY_DIR/dnf-before.XXXXXX")"
  before_flatpak="$(mktemp "$PEGASUS_RECOVERY_DIR/flatpak-before.XXXXXX")"
  dnf repoquery --userinstalled --qf '%{name}' 2>/dev/null | sort -u > "$before_dnf" || true
  flatpak list --app --columns=application 2>/dev/null | sort -u > "$before_flatpak" || true
  installer_manifest_update --arg dnf "$before_dnf" --arg flatpak "$before_flatpak" '.snapshots.before_dnf=$dnf | .snapshots.before_flatpak=$flatpak'
}

installer_manifest_finalize_packages() {
  local before_dnf before_flatpak after_dnf after_flatpak
  before_dnf="$(jq -r '.snapshots.before_dnf // empty' "$PEGASUS_MANIFEST_FILE")"; before_flatpak="$(jq -r '.snapshots.before_flatpak // empty' "$PEGASUS_MANIFEST_FILE")"
  after_dnf="$(mktemp "$PEGASUS_RECOVERY_DIR/dnf-after.XXXXXX")"; after_flatpak="$(mktemp "$PEGASUS_RECOVERY_DIR/flatpak-after.XXXXXX")"
  dnf repoquery --userinstalled --qf '%{name}' 2>/dev/null | sort -u > "$after_dnf" || true
  flatpak list --app --columns=application 2>/dev/null | sort -u > "$after_flatpak" || true
  if [ -f "$before_dnf" ]; then
    local dnf_json; dnf_json="$(comm -13 "$before_dnf" "$after_dnf" | jq -Rsc 'split("\n")|map(select(length>0))')"
    installer_manifest_update --argjson values "$dnf_json" '.packages.dnf = ($values | unique)'
  fi
  if [ -f "$before_flatpak" ]; then
    local flatpak_json; flatpak_json="$(comm -13 "$before_flatpak" "$after_flatpak" | jq -Rsc 'split("\n")|map(select(length>0))')"
    installer_manifest_update --argjson values "$flatpak_json" '.packages.flatpak = ($values | unique)'
  fi
}

installer_manifest_refresh_files() {
  local path hash
  while IFS= read -r path; do
    if [ -L "$path" ]; then hash="$(readlink "$path")"; elif [ -f "$path" ]; then hash="$(sha256sum "$path" | cut -d' ' -f1)"; elif [ -d "$path" ]; then hash="directory"; else hash=""; fi
    installer_manifest_update --arg path "$path" --arg hash "$hash" '(.files[] | select(.path==$path) | .managed_hash)=$hash'
  done < <(jq -r '.files[].path' "$PEGASUS_MANIFEST_FILE")
}

installer_state_update() {
  local filter="$1" tmp
  shift
  tmp="$(mktemp "${PEGASUS_STATE_FILE}.XXXXXX")"
  jq "$@" "$filter" "$PEGASUS_STATE_FILE" > "$tmp" && mv "$tmp" "$PEGASUS_STATE_FILE"
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
