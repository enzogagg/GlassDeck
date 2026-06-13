#!/usr/bin/env bash
set -euo pipefail

LABEL="ovh.ega.glassdeck.mac-daemon"
PLIST_FILE="$HOME/Library/LaunchAgents/$LABEL.plist"
DOMAIN="gui/$(id -u)"

case "${1:-status}" in
  start)
    if [ ! -f "$PLIST_FILE" ]; then
      echo "LaunchAgent is not installed. Run ./scripts/install-mac.sh first." >&2
      exit 1
    fi
    launchctl bootstrap "$DOMAIN" "$PLIST_FILE" >/dev/null 2>&1 || true
    launchctl enable "$DOMAIN/$LABEL"
    launchctl kickstart -k "$DOMAIN/$LABEL"
    ;;
  stop)
    launchctl bootout "$DOMAIN" "$PLIST_FILE" >/dev/null 2>&1 || true
    ;;
  restart)
    "$0" stop
    "$0" start
    ;;
  status)
    launchctl print "$DOMAIN/$LABEL"
    ;;
  *)
    echo "Usage: $0 {start|stop|restart|status}" >&2
    exit 1
    ;;
esac
