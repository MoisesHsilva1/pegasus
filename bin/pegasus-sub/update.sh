#!/bin/bash

PEGASUS_PATH="${PEGASUS_PATH:-$HOME/.local/share/pegasus}"
[ ! -d "$PEGASUS_PATH" ] && PEGASUS_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

CHOICES=(
	"Pegasus        Update Pegasus itself and run any migrations"
	"LazyGit        TUI for Git"
	"LazyDocker     TUI for Docker"
	"Zellij         Adds panes, tabs, and sessions to the terminal"
	"<< Back        "
)

CHOICE=$(gum choose "${CHOICES[@]}" --height 10 --header "Update manually-managed applications")

if [[ "$CHOICE" == "<< Back"* ]] || [[ -z "$CHOICE" ]]; then
	echo ""
else
	INSTALLER=$(echo "$CHOICE" | awk -F ' {2,}' '{print $1}' | tr '[:upper:]' '[:lower:]' | sed 's/ /-/g')

	case "$INSTALLER" in
	"pegasus-fedora"|"pegasus") INSTALLER_FILE="$PEGASUS_PATH/bin/pegasus-sub/migrate.sh" ;;
	*) INSTALLER_FILE="$PEGASUS_PATH/install/terminal/app-$INSTALLER.sh" ;;
	esac

	[ -f "$INSTALLER_FILE" ] && source $INSTALLER_FILE && gum spin --spinner globe --title "Update completed!" -- sleep 3
fi

clear
source "$PEGASUS_PATH/bin/pegasus"
