#!/bin/bash

set -e

ascii_art='
__________                                                              
\______   \____   ____ _____    ________ __ __  ______    
 |     ___/ __ \ / ___\\__  \  /  ___/  |  \  \/  ___/    
 |    |  \  ___// /_/  >/ __ \_\___ \|  |  /\  /\___ \    
 |____|   \___  >___  /(____  /____  >____/  \/____  >  
              \/_____/      \/     \/              \/      
'

echo -e "$ascii_art"
echo "=> Pegasus is for fresh Fedora Workstation installations only!"
echo -e "\nBegin installation (or abort with ctrl+c)..."

echo "Checking initial dependencies..."
if command -v apt-get >/dev/null 2>&1; then
  sudo apt-get update -y >/dev/null || true
  sudo apt-get install -y git curl wget >/dev/null || true
elif command -v dnf >/dev/null 2>&1; then
  sudo dnf check-update >/dev/null || true
  sudo dnf install -y git curl wget >/dev/null || true
fi

echo "Cloning Pegasus..."
rm -rf ~/.local/share/pegasus
git clone https://github.com/MoisesHsilva1/Pegasus.git ~/.local/share/pegasus >/dev/null
if [[ "${PEGASUS_REF:-}" != "master" && -n "${PEGASUS_REF:-}" ]]; then
	cd ~/.local/share/pegasus
	git fetch origin "${PEGASUS_REF:-stable}" && git checkout "${PEGASUS_REF:-stable}"
	cd -
fi

echo "Installation starting..."
source ~/.local/share/pegasus/install.sh
