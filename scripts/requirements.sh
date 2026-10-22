#!/bin/bash

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PEGASUS_DIR="${PEGASUS_DIR:-$(cd "$_SCRIPT_DIR/.." && pwd)}"
source "$PEGASUS_DIR/scripts/ui.sh"

check_system_requirements() {
  print_section "System Validation Checks"

  # 1. Non-root guard
  if [ "$EUID" -eq 0 ]; then
    print_box_error "Do not run install.sh with sudo!"
    echo "Pegasus must be executed as a standard user."
    echo "The installer will request your sudo password when necessary for system operations."
    exit 1
  fi
  step_success "Running as standard user ($USER)"

  # 2. OS distribution check
  if [ ! -f /etc/os-release ]; then
    step_error "Unable to determine OS (/etc/os-release not found)"
    exit 1
  fi

  source /etc/os-release
  if [ "${ID:-}" != fedora ]; then
    step_error "Unsupported OS: ${ID:-unknown} ($NAME)"
    echo "Pegasus supports Fedora Workstation with GNOME only."
    exit 1
  fi
  case "${VARIANT_ID:-workstation}" in
    workstation|workstation-product) step_success "Fedora Workstation detected ($NAME ${VERSION_ID:-})" ;;
    *) step_error "Fedora Workstation is required (variant: ${VARIANT_ID:-unknown})"; exit 1 ;;
  esac
  [[ "${XDG_CURRENT_DESKTOP:-}:${XDG_SESSION_DESKTOP:-}" == *GNOME* ]] || { step_error "An active GNOME session is required"; exit 1; }

  # 3. Architecture check
  ARCH="$(uname -m)"
  if [ "$ARCH" != "x86_64" ]; then
    step_error "Unsupported architecture: $ARCH (Requires x86_64)"
    exit 1
  fi
  step_success "Supported architecture: $ARCH"

  # 4. Internet connection check
  step_info "Checking network connectivity..."
  if ! curl -s --connect-timeout 5 https://fedoraproject.org >/dev/null && ! curl -s --connect-timeout 5 https://github.com >/dev/null; then
    step_error "No active internet connection detected"
    echo "An active internet connection is required to download packages and repositories."
    exit 1
  fi
  step_success "Internet connection verified"

  # 5. Base tools and dependencies verification & auto-install
  step_info "Checking Pegasus dependencies..."

  local base_pkgs_to_install=()
  local required_tools=(
    "git:git"
    "curl:curl"
    "wget:wget"
    "unzip:unzip"
    "jq:jq"
    "flatpak:flatpak"
    "gsettings:glib2"
  )

  for entry in "${required_tools[@]}"; do
    local cmd="${entry%%:*}"
    local pkg="${entry##*:}"
    if ! command -v "$cmd" >/dev/null 2>&1; then
      base_pkgs_to_install+=("$pkg")
    fi
  done

  if [ ${#base_pkgs_to_install[@]} -gt 0 ]; then
    step_info "Installing missing base system packages (${base_pkgs_to_install[*]})..."
    sudo dnf install -y "${base_pkgs_to_install[@]}" >/dev/null || exit 1
  fi

  # Check and install gum if missing
  if ! command -v gum >/dev/null 2>&1; then
    step_info "Installing missing dependency: gum..."
    if [ -f "$PEGASUS_DIR/install/terminal/required/app-gum.sh" ]; then
      source "$PEGASUS_DIR/install/terminal/required/app-gum.sh" || true
    fi
  fi

  # Check and install mise if missing
  if ! command -v mise >/dev/null 2>&1; then
    step_info "Installing missing dependency: mise..."
    if [ -f "$PEGASUS_DIR/install/terminal/required/app-mise.sh" ]; then
      source "$PEGASUS_DIR/install/terminal/required/app-mise.sh" || true
    fi
  fi

  # Validate all required tools and output individual statuses
  local missing_tools=()
  local tools_to_check=("git" "curl" "wget" "unzip" "jq" "flatpak" "gsettings" "gum" "mise")

  for tool in "${tools_to_check[@]}"; do
    if command -v "$tool" >/dev/null 2>&1; then
      step_success "$tool installed"
    else
      step_error "$tool is missing and could not be installed automatically"
      missing_tools+=("$tool")
    fi
  done

  if [ ${#missing_tools[@]} -gt 0 ]; then
    print_box_error "Required Pegasus dependencies are missing: ${missing_tools[*]}"
    echo "Please install the missing tools manually before continuing."
    exit 1
  fi

  step_success "Base system requirements and CLI dependencies met"
}


check_system_requirements

