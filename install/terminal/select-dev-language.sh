#!/bin/bash
set -euo pipefail

# Ensure PATH contains common binary directories for mise & custom tools
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:/usr/local/bin:$PATH"

# Function to ensure mise is installed and available
ensure_mise() {
  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash 2>/dev/null)" || true
    return 0
  fi

  echo "[•] Checking 'mise' version manager dependency..."
  local _DIR
  _DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  if [ -f "$_DIR/required/app-mise.sh" ]; then
    source "$_DIR/required/app-mise.sh" || true
  fi

  export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:/usr/local/bin:$PATH"

  if command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash 2>/dev/null)" || true
    return 0
  fi

  echo ""
  echo "ERROR: 'mise' command not found!"
  echo "Mise version manager is required to install and manage runtime languages."
  echo "Please install mise manually: https://mise.jdx.dev/ or run: curl https://mise.run | sh"
  exit 1
}

# Install default programming languages
LANGS="${PEGASUS_FIRST_RUN_LANGUAGES:-}"
if [[ -n "$LANGS" ]]; then
  languages=$LANGS
else
  if ! command -v gum >/dev/null 2>&1; then
    _DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    _ROOT="${PEGASUS_PATH:-$(cd "$_DIR/../.." && pwd)}"
    [ -f "$_ROOT/install/terminal/required/app-gum.sh" ] && source "$_ROOT/install/terminal/required/app-gum.sh" || true
  fi
  if command -v gum >/dev/null 2>&1; then
    AVAILABLE_LANGUAGES=("Ruby on Rails" "Node.js" "Go" "PHP" "Python" "Elixir" "Rust" "Java")
    languages=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --height 10 --header "Select programming languages" || true)
  else
    languages=""
  fi
fi

if [[ -n "${languages:-}" ]]; then
  # Ensure mise is ready if any mise-managed language is selected
  if [[ "$languages" =~ (Ruby|Rails|Node|Go|Python|Elixir|Java) ]]; then
    ensure_mise
  fi

  for language in $languages; do
    case $language in
    Ruby|Rails)
      mise use --global ruby@latest
      mise settings add idiomatic_version_file_enable_tools ruby
      mise x ruby -- gem install rails --no-document
      ;;
    Node.js)
      mise use --global node@lts
      ;;
    Go)
      mise use --global go@latest
      ;;
    PHP)
      sudo dnf -y install php php-{cli,curl,intl,mbstring,opcache,pgsql,mysqlnd,pdo,xml,zip}
      php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
      php composer-setup.php --quiet && sudo mv composer.phar /usr/local/bin/composer
      rm composer-setup.php
      ;;
    Python)
      mise use --global python@latest
      ;;
    Elixir)
      mise use --global erlang@latest
      mise use --global elixir@latest
      mise x elixir -- mix local.hex --force
      ;;
    Rust)
      if ! command -v rustc >/dev/null 2>&1 && ! command -v cargo >/dev/null 2>&1; then
        bash -c "$(curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs)" -- -y
      fi
      ;;
    Java)
      mise use --global java@latest
      ;;
    esac
  done
fi

