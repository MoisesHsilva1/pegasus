#!/bin/bash

# This file is copied to ~/.local/bin and is intentionally self-contained.
set -u
state_dir="${XDG_STATE_HOME:-$HOME/.local/state}/pegasus/recovery"
manifest="$state_dir/manifest.json"
backup_dir="$state_dir/backups"
report=""
dry_run=0
assume_yes=0
purge=0
result=0

usage() { echo "Usage: pegasus-uninstall [--dry-run] [--yes] [--report FILE] [--purge-recovery]"; }
log() { printf '%s\n' "$*"; [ -n "$report" ] && printf '%s\n' "$*" >> "$report"; }
hash_file() { if [ -L "$1" ]; then readlink "$1"; else sha256sum "$1" 2>/dev/null | cut -d' ' -f1; fi; }
same_file() { [ -f "$1" ] && [ "$(hash_file "$1")" = "$2" ]; }
record() { log "[$1] $2${3:+ — $3}"; [ "$1" = conflict ] && result=2; }
plan() {
  log "Planned resource review:"
  jq -r '.files[]? | "  file: \(.path) (\(.type), original=\(.original))"' "$manifest"
  jq -r '.settings[]? | "  setting: \(.schema) \(.key)"' "$manifest"
  log "  packages: DNF=$(jq -r '.packages.dnf | join(", ")' "$manifest") Flatpak=$(jq -r '.packages.flatpak | join(", ")' "$manifest")"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --dry-run) dry_run=1;; --yes) assume_yes=1;; --purge-recovery) purge=1;;
      --report) shift; report="${1:-}"; [ -n "$report" ] || { usage >&2; return 2; };;
      -h|--help) usage; exit 0;; *) usage >&2; return 2;;
    esac; shift
  done
}

restore_file() {
  local path="$1" type="$2" original="$3" backup="$4" managed="$5" current
  if [ "$original" = true ]; then
    if [ ! -e "$path" ] && [ ! -L "$path" ]; then
      [ "$backup" != "-" ] && [ -e "$backup" ] || { record failed "$path" "backup missing"; return; }
      [ "$dry_run" -eq 0 ] && mkdir -p "$(dirname "$path")" && cp -a "$backup" "$path"
      record restored "$path"; return
    fi
    current="$(hash_file "$path")"
    if [ -n "$managed" ] && [ "$current" = "$managed" ]; then
      [ "$dry_run" -eq 0 ] && cp -a "$backup" "$path"
      record restored "$path"; return
    fi
    record conflict "$path" "changed after Pegasus; preserved"; return
  fi
  if [ ! -e "$path" ] && [ ! -L "$path" ]; then record ignored "$path" "already absent"; return; fi
  if [ "$type" = directory ]; then
    if [ -z "$(find "$path" -mindepth 1 -print -quit 2>/dev/null)" ]; then
      [ "$dry_run" -eq 0 ] && rmdir "$path"
      record removed "$path" "empty directory"
    else
      record conflict "$path" "directory is not empty; preserved"
    fi
    return
  fi
  current="$(hash_file "$path")"
  if [ -n "$managed" ] && [ "$current" = "$managed" ]; then
    [ "$dry_run" -eq 0 ] && rm -f "$path"
    record removed "$path"
  else record conflict "$path" "created resource changed after Pegasus; preserved"; fi
}

restore_setting() {
  local schema="$1" key="$2" original="$3" applied current
  command -v gsettings >/dev/null 2>&1 || { record skipped "$schema $key" "gsettings unavailable"; return; }
  current="$(gsettings get "$schema" "$key" 2>/dev/null || true)"; applied="$4"
  if [ -n "$applied" ] && [ "$current" = "$applied" ]; then
    [ "$dry_run" -eq 0 ] && gsettings set "$schema" "$key" "$original" >/dev/null 2>&1
    record restored "$schema $key"
  else record conflict "$schema $key" "changed after Pegasus; preserved"; fi
}

main() {
  parse_args "$@" || exit $?
  [ -r "$manifest" ] || { echo "Pegasus recovery manifest not found: $manifest" >&2; exit 1; }
  jq empty "$manifest" >/dev/null 2>&1 || { echo "Pegasus recovery manifest is invalid" >&2; exit 1; }
  [ -n "$report" ] || report="$state_dir/uninstall-report-$(date +%Y%m%d-%H%M%S).log"
  if [ -n "$report" ]; then mkdir -p "$(dirname "$report")"; : > "$report"; fi
  log "Pegasus safe uninstall — manifest $manifest"
  plan
  if [ "$dry_run" -eq 0 ] && [ "$assume_yes" -eq 0 ]; then
    printf 'Proceed with safe Pegasus uninstallation? [y/N] '; read -r answer
    [[ "$answer" =~ ^[Yy]$ ]] || { log "Cancelled"; exit 0; }
  fi
  while IFS=$'\t' read -r path type original backup managed; do restore_file "$path" "$type" "$original" "$backup" "$managed"; done < <(jq -r '.files[]? | [.path,.type,.original, (.backup // "-"), (.managed_hash // "-")] | @tsv' "$manifest")
  while IFS=$'\t' read -r schema key original applied; do restore_setting "$schema" "$key" "$original" "$applied"; done < <(jq -r '.settings[]? | [.schema,.key,.original,(.last_applied // "")] | @tsv' "$manifest")
  if [ "$dry_run" -eq 0 ] && [ "$assume_yes" -eq 1 ]; then :; fi
  dnf_packages="$(jq -r '.packages.dnf[]?' "$manifest" | paste -sd' ' -)"
  flatpak_packages="$(jq -r '.packages.flatpak[]?' "$manifest" | paste -sd' ' -)"
  if [ -n "$dnf_packages$flatpak_packages" ]; then
    log "Recorded new packages: DNF=[$dnf_packages] Flatpak=[$flatpak_packages]"
    remove_packages=0
    if [ "$dry_run" -eq 1 ]; then
      log "[plan] packages would be offered for removal"
    elif [ "$assume_yes" -eq 1 ]; then
      remove_packages=1
    else
      printf 'Remove packages installed by Pegasus and absent before installation? [y/N] '; read -r package_answer
      [[ "$package_answer" =~ ^[Yy]$ ]] && remove_packages=1
    fi
    if [ "$remove_packages" -eq 1 ]; then
      [ -z "$dnf_packages" ] || sudo dnf remove -y $dnf_packages >/dev/null 2>&1 || record failed "DNF packages" "removal failed"
      [ -z "$flatpak_packages" ] || flatpak uninstall -y $flatpak_packages >/dev/null 2>&1 || record failed "Flatpak packages" "removal failed"
    else
      log "Package removal declined; packages preserved"
    fi
  fi
  if [ "$purge" -eq 1 ] && [ "$dry_run" -eq 0 ] && [ "$result" -eq 0 ]; then rm -rf "$backup_dir"; rm -f "$manifest"; log "Recovery data purged"; fi
  log "Safe uninstall finished (exit status $result)"
  exit "$result"
}
main "$@"
