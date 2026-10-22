#!/bin/bash

# Set common git aliases
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global pull.rebase true

# Set identification from install inputs
GIT_NAME="${PEGASUS_USER_NAME:-}"
GIT_EMAIL="${PEGASUS_USER_EMAIL:-}"

if [[ -n "${GIT_NAME//[[:space:]]/}" ]]; then
  git config --global user.name "$GIT_NAME"
fi

if [[ -n "${GIT_EMAIL//[[:space:]]/}" ]]; then
  git config --global user.email "$GIT_EMAIL"
fi
