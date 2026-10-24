#!/bin/bash

# Gum is used for interactive CLI prompts and menus in Pegasus
install_gum() {
  if command -v gum >/dev/null 2>&1 && gum --version >/dev/null 2>&1; then
    return 0
  fi

  local tmp_dir gum_rpm gum_url
  tmp_dir=$(mktemp -d) || {
    echo "Unable to create a temporary directory for gum." >&2
    return 1
  }
  if command -v dnf >/dev/null 2>&1; then
    gum_rpm="${tmp_dir}/gum.rpm"
    gum_url=""
    if gum_url=$(curl -fsSL --connect-timeout 10 --retry 2 \
      "https://api.github.com/repos/charmbracelet/gum/releases/latest" 2>/dev/null \
      | grep -Po '"browser_download_url": "\K[^"]*x86_64\.rpm' | head -n 1); then
      :
    else
      gum_url=""
    fi
    if [ -z "$gum_url" ]; then
      gum_url="https://github.com/charmbracelet/gum/releases/download/v0.17.0/gum-0.17.0-1.x86_64.rpm"
    fi

    echo "Downloading gum from Charmbracelet..."
    if curl -fL --connect-timeout 10 --retry 2 -o "$gum_rpm" "$gum_url"; then
      if ! sudo dnf install -y "$gum_rpm"; then
        echo "DNF could not install the downloaded gum package." >&2
      fi
    else
      echo "Could not download the gum package from $gum_url." >&2
    fi

    if ! command -v gum >/dev/null 2>&1; then
      if [ ! -f /etc/yum.repos.d/charm.repo ]; then
        if ! printf '%s\n' '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | sudo tee /etc/yum.repos.d/charm.repo >/dev/null; then
          echo "Could not configure the Charm repository." >&2
        fi
      fi
      if ! sudo dnf install -y gum; then
        echo "Could not install gum from the Charm repository." >&2
      fi
    fi
  else
    echo "DNF is required to install gum automatically." >&2
  fi

  if command -v gum >/dev/null 2>&1 && gum --version >/dev/null 2>&1; then
    rm -rf "$tmp_dir"
    return 0
  fi

  rm -rf "$tmp_dir"
  echo "Automatic gum installation did not provide a usable command." >&2
  return 1
}

install_gum
