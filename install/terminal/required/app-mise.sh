#!/bin/bash
set -euo pipefail

# Ensure PATH contains common binary directories for mise
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:/usr/local/bin:$PATH"

install_mise() {
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash 2>/dev/null)" || true
    return 0
  fi

  echo "Installing Mise version manager..."

  if command -v dnf >/dev/null 2>&1; then
    if [ ! -f /etc/yum.repos.d/mise.repo ]; then
      sudo dnf config-manager --add-repo https://mise.jdx.dev/rpm/mise.repo >/dev/null 2>&1 || true
    fi
    sudo dnf install -y mise >/dev/null 2>&1 || true
  fi

  if ! command -v mise >/dev/null 2>&1; then
    # Universal standalone installer script
    curl -fsSL https://mise.run | sh >/dev/null 2>&1 || true
  fi

  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:/usr/local/bin:$PATH"

  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash 2>/dev/null)" || true
    return 0
  else
    return 1
  fi
}

install_mise
