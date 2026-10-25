#!/bin/bash

# Compatibility entrypoint. The persistent copy is autonomous and survives removal
# of ~/.local/share/pegasus.
set -u
if [ -x "$HOME/.local/bin/pegasus-uninstall" ] && [ "$(readlink -f "$HOME/.local/bin/pegasus-uninstall" 2>/dev/null || true)" != "$(readlink -f "$0" 2>/dev/null || true)" ]; then
  exec "$HOME/.local/bin/pegasus-uninstall" "$@"
fi
echo "Pegasus safe uninstaller is not installed; no changes were made." >&2
exit 1
