#!/bin/bash

# Base packages are installed by the dependencies stage. This stage only runs
# terminal-specific installers, avoiding duplicate DNF transactions.

PEGASUS_DIR="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"
[ ! -d "$PEGASUS_DIR" ] && PEGASUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Run terminal installers
for installer in "$PEGASUS_DIR"/install/terminal/*.sh; do
  [ -f "$installer" ] && source "$installer"
done
