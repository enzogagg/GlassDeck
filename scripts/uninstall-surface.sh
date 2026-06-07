#!/usr/bin/env bash
set -euo pipefail

APP_NAME="glassdeck"
BIN_NAME="surface-client"
COMMAND_NAME="glassdeck-surface"
SERVICE_NAME="glassdeck-surface.service"

INSTALL_PREFIX="${GLASSDECK_INSTALL_PREFIX:-$HOME/.local/opt/$APP_NAME}"
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

if command -v systemctl >/dev/null 2>&1; then
  systemctl --user disable --now "$SERVICE_NAME" >/dev/null 2>&1 || true
  rm -f "$SYSTEMD_USER_DIR/$SERVICE_NAME"
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

rm -f "$USER_BIN_DIR/$COMMAND_NAME"
rm -f "$INSTALL_PREFIX/bin/$BIN_NAME"

if [[ -d "$INSTALL_PREFIX" ]]; then
  rmdir "$INSTALL_PREFIX/bin" >/dev/null 2>&1 || true
  rmdir "$INSTALL_PREFIX" >/dev/null 2>&1 || true
fi

echo "GlassDeck Surface client uninstalled for the current user."
