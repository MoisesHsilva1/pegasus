#!/bin/bash

set -u

PEGASUS_DIR="${PEGASUS_PATH:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
[ -f "$PEGASUS_DIR/scripts/installer-state.sh" ] || PEGASUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PEGASUS_PATH="$PEGASUS_DIR"
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:/usr/local/bin:$PATH"

source "$PEGASUS_DIR/scripts/ui.sh"
source "$PEGASUS_DIR/scripts/installer-state.sh"

YES=0
RESUME=0
REVIEW=0

usage() {
  cat <<EOF
Usage: $0 [--yes] [--resume] [--review]

  --yes       accept the displayed plan and use default choices
  --resume    run only pending or failed steps
  --review    edit choices and steps without running installation
EOF
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --yes) YES=1 ;;
      --resume) RESUME=1 ;;
      --review) REVIEW=1 ;;
      -h|--help) usage; exit 0 ;;
      *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
  done
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || { step_error "Missing required dependency: $1"; return 1; }
}

validate_system() {
  print_section "System validation"
  [ "$EUID" -ne 0 ] || { print_box_error "Do not run Pegasus as root"; return 1; }
  [ -r /etc/os-release ] || { step_error "Cannot read /etc/os-release"; return 1; }
  source /etc/os-release
  [ "${ID:-}" = fedora ] || { step_error "Pegasus requires Fedora Workstation; detected ${ID:-unknown}"; return 1; }
  case "${VARIANT_ID:-workstation}" in workstation|workstation-product) ;; *) step_error "Fedora Workstation is required (variant: ${VARIANT_ID:-unknown})"; return 1 ;; esac
  [[ "${XDG_CURRENT_DESKTOP:-}:${XDG_SESSION_DESKTOP:-}" == *GNOME* ]] || { step_error "An active GNOME session is required"; return 1; }
  [ "$(uname -m)" = x86_64 ] || { step_error "Unsupported architecture: $(uname -m)"; return 1; }
  for tool in sudo dnf curl git jq flatpak; do require_command "$tool" || return 1; done
  curl -fsS --connect-timeout 5 https://fedoraproject.org/ >/dev/null || { step_error "Network connectivity check failed"; return 1; }
  step_success "Fedora Workstation, GNOME, x86_64, network and required tools verified"
}

bootstrap_user_install() {
  chmod +x "$PEGASUS_DIR"/{install.sh,boot.sh,update.sh,uninstall.sh} "$PEGASUS_DIR/bin/pegasus" "$PEGASUS_DIR/bin/pegasus-sub"/*.sh "$PEGASUS_DIR/scripts"/*.sh 2>/dev/null || step_warn "Could not update all executable bits"
  mkdir -p "$HOME/.local/bin" "$HOME/.local/share"
  if [ "$PEGASUS_DIR" != "$HOME/.local/share/pegasus" ] && [ ! -e "$HOME/.local/share/pegasus" ]; then ln -s "$PEGASUS_DIR" "$HOME/.local/share/pegasus"; fi
  ln -sfn "$PEGASUS_DIR/bin/pegasus" "$HOME/.local/bin/pegasus"
  if [ -f "$HOME/.bashrc" ] && ! grep -q "pegasus/defaults/bash/rc" "$HOME/.bashrc"; then
    printf '\n# Pegasus Linux Configuration\nif [ -f ~/.local/share/pegasus/defaults/bash/rc ]; then\n  source ~/.local/share/pegasus/defaults/bash/rc\nfi\n' >> "$HOME/.bashrc"
  fi
}

default_choices() {
  [ "$(jq -r '.choices.optional_apps // empty' "$PEGASUS_STATE_FILE")" ] || installer_state_set_choice optional_apps "Spotify,OBS-Studio,1Password"
  [ "$(jq -r '.choices.languages // empty' "$PEGASUS_STATE_FILE")" ] || installer_state_set_choice languages "Node.js,Python,Java"
  [ "$(jq -r '.choices.user_name // empty' "$PEGASUS_STATE_FILE")" ] || installer_state_set_choice user_name "$(getent passwd "$USER" | cut -d: -f5 | cut -d, -f1)"
}

edit_choices() {
  local apps langs name email
  apps="$(jq -r '.choices.optional_apps // "Spotify,OBS-Studio,1Password"' "$PEGASUS_STATE_FILE")"
  langs="$(jq -r '.choices.languages // "Node.js,Python,Java"' "$PEGASUS_STATE_FILE")"
  name="$(jq -r '.choices.user_name // ""' "$PEGASUS_STATE_FILE")"
  email="$(jq -r '.choices.user_email // ""' "$PEGASUS_STATE_FILE")"
  if command -v gum >/dev/null 2>&1 && [ "$YES" -eq 0 ]; then
    apps="$(gum choose Spotify OBS-Studio 1Password Mainline-Kernels --no-limit --selected "$apps" --header 'Optional apps' | tr ' ' '-')" || return 1
    langs="$(gum choose 'Ruby on Rails' Node.js Go PHP Python Elixir Rust Java --no-limit --selected "$langs" --header 'Languages' | tr '\n' ',')" || return 1
    name="$(gum input --value "$name" --prompt 'Name> ')" || return 1
    email="$(gum input --value "$email" --prompt 'Email> ')" || return 1
  fi
  installer_state_set_choice optional_apps "$apps"
  installer_state_set_choice languages "$langs"
  installer_state_set_choice user_name "$name"
  installer_state_set_choice user_email "$email"
}

show_plan() {
  print_section "Installation plan"
  echo "Platform: Fedora Workstation + GNOME"
  echo "Apps: Alacritty, GNOME Sushi/Tweaks/Software, wl-clipboard, Ulauncher, VS Code, LibreOffice, Obsidian, DBeaver, Postman, IntelliJ IDEA"
  echo "Optional apps: $(jq -r '.choices.optional_apps // "none"' "$PEGASUS_STATE_FILE")"
  echo "Languages: $(jq -r '.choices.languages // "none"' "$PEGASUS_STATE_FILE")"
  echo "Sudo: package installation, repositories and system settings"
  echo "External repositories: Microsoft VS Code and Flathub"
  echo "User changes: shell hook, GNOME settings and Alacritty style (existing files preserved by default)"
}

run_step() {
  local id="$1" title="$2" command_file="$3" status
  if [ "$RESUME" -eq 1 ] && [ "$(installer_state_step_status "$id")" = success ]; then step_info "$title (already complete; skipped)"; return 0; fi
  print_section "$title"
  installer_state_set_step "$id" running
  set +e; ( source "$PEGASUS_DIR/$command_file" ); status=$?; set -e
  if [ "$status" -eq 0 ]; then installer_state_set_step "$id" success; step_success "$title"; return 0; fi
  installer_state_set_step "$id" failed "exit $status"
  step_error "$title failed (exit $status). Retry with 'pegasus install --resume'."
  return 1
}

run_optional() {
  local app="$1" file="$PEGASUS_DIR/install/desktop/optional/app-${app,,}.sh" result
  local step="optional_${app,,}"
  if [ "$RESUME" -eq 1 ] && [ "$(installer_state_step_status "$step")" = success ]; then
    step_info "Optional app $app (already complete; skipped)"
    return 0
  fi
  if [ ! -f "$file" ]; then
    installer_state_set_step "$step" skipped "installer unavailable"
    step_warn "Optional app $app is unavailable; skipped"
    return 0
  fi
  installer_state_set_step "$step" running
  set +e; ( source "$file" ); result=$?; set -e
  if [ "$result" -eq 0 ]; then
    installer_state_set_step "$step" success
  else
    installer_state_set_step "$step" failed "exit $result"
    step_warn "Optional app $app failed; continuing"
  fi
  return 0
}

summarize() {
  print_section "Installation summary"
  jq -r '.steps | to_entries[] | "\(.key): \(.value.status)\(if .value.reason then " (\(.value.reason))" else "" end)"' "$PEGASUS_STATE_FILE"
  if jq -e '[.steps[] | select(.status=="failed" or .status=="blocked")] | length > 0' "$PEGASUS_STATE_FILE" >/dev/null; then
    print_box_warn "Installation has pending or failed steps. Review $PEGASUS_LOG_FILE and run: pegasus install --resume"
    return 2
  fi
  print_summary
}

main() {
  parse_args "$@"
  installer_state_init
  installer_log_start
  print_banner
  validate_system || { installer_state_set_step prerequisites blocked "system validation failed"; return 1; }
  installer_state_set_step prerequisites success
  default_choices
  if [ "$RESUME" -eq 0 ]; then
    edit_choices || { step_warn "Selection cancelled; no installation was run"; return 1; }
  fi
  show_plan
  [ "$REVIEW" -eq 1 ] && { step_success "Review complete"; return 0; }
  [ "$YES" -eq 1 ] || gum confirm "Proceed with this plan?" || { step_warn "Installation cancelled"; return 1; }
  export PEGASUS_INSTALLER_YES="$YES"
  bootstrap_user_install
  run_step dependencies "Base dependencies" scripts/packages.sh || true
  run_step terminal "Shell and terminal tools" install/terminal.sh || true
  run_step alacritty "Alacritty and fonts" install/desktop/app-alacritty.sh || true
  run_step desktop_apps "Desktop applications" scripts/applications.sh || true
  run_step languages "Selected language runtimes" install/terminal/select-dev-language.sh || true
  run_step gnome "GNOME configuration" scripts/gnome.sh || true
  local app apps; apps="$(jq -r '.choices.optional_apps // ""' "$PEGASUS_STATE_FILE")"
  for app in ${apps//,/ }; do run_optional "$app"; done
  installer_state_set_step finalize success
  summarize
}

main "$@"
