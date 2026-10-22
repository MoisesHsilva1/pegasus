#!/bin/bash

# Pegasus installer entry point. The stateful workflow lives in scripts/installer.sh.
set -u

PEGASUS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -z "${PEGASUS_PATH:-}" ] || [ ! -f "$PEGASUS_PATH/scripts/installer.sh" ]; then
  export PEGASUS_PATH="$PEGASUS_DIR"
fi
export OMAKUB_PATH="$PEGASUS_PATH"
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/bin:/usr/local/bin:$PATH"

exec "$PEGASUS_DIR/scripts/installer.sh" "$@"
