#!/usr/bin/env bash
set -euo pipefail

LABEL="ovh.ega.glassdeck.mac-daemon"
PLIST_FILE="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"
ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/scripts/install-mac.sh"

install_or_repair() {
  if [ ! -x "$INSTALL_SCRIPT" ]; then
    echo "Install script not found or not executable: $INSTALL_SCRIPT" >&2
    exit 1
  fi

  "$INSTALL_SCRIPT"
}

case "${1:-status}" in
  start)
    if [ ! -f "$PLIST_FILE" ]; then
      install_or_repair
      exit 0
    fi
    launchctl bootstrap "$DOMAIN" "$PLIST_FILE" >/dev/null 2>&1 || true
    launchctl enable "$DOMAIN/$LABEL"
    launchctl kickstart -k "$DOMAIN/$LABEL"
    ;;
  stop)
    launchctl bootout "$DOMAIN" "$PLIST_FILE" >/dev/null 2>&1 || true
    ;;
  restart)
    install_or_repair
    ;;
  repair)
    install_or_repair
    ;;
  status)
    launchctl print "$DOMAIN/$LABEL"
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|repair|status}" >&2
    exit 1
    ;;
esac
