#!/bin/bash

# Uninstall default programming languages
LANGS="${PEGASUS_FIRST_RUN_LANGUAGES:-}"
if [[ -n "$LANGS" ]]; then
  languages=$LANGS
else
  AVAILABLE_LANGUAGES=("Ruby on Rails" "Node.js" "Go" "PHP" "Python" "Elixir" "Rust" "Java")
  languages=$(gum choose "${AVAILABLE_LANGUAGES[@]}" --no-limit --height 10 --header "Select programming languages to uninstall")
fi

if [[ -n $languages ]]; then
  for language in $languages; do
    case $language in
    Ruby)
      mise uninstall ruby@latest 2>/dev/null || true
      ;;
    Node.js)
      mise uninstall node@lts 2>/dev/null || true
      ;;
    Go)
      mise uninstall go@latest 2>/dev/null || true
      ;;
    PHP)
      sudo dnf -y remove php php-{cli,curl,intl,mbstring,opcache,pgsql,mysqlnd,pdo,xml,zip} >/dev/null 2>&1 || true
      sudo rm -f /usr/local/bin/composer
      ;;
    Python)
      mise uninstall python@latest 2>/dev/null || true
      ;;
    Elixir)
      mise uninstall elixir@latest 2>/dev/null || true
      mise uninstall erlang@latest 2>/dev/null || true
      ;;
    Rust)
      rustup self uninstall -y 2>/dev/null || true
      ;;
    Java)
      mise uninstall java@latest 2>/dev/null || true
      ;;
    esac
  done
fi
