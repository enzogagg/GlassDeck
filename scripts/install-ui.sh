#!/usr/bin/env bash
set -euo pipefail

# GlassDeck UI Installer
# Sets up the Surface Web Interface to launch automatically on boot.

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
UNIT_FILE="$SYSTEMD_USER_DIR/glassdeck-ui.service"

echo "Installing GlassDeck UI service..."

mkdir -p "$SYSTEMD_USER_DIR"

# Note: We use 'restart-surface.sh' as the entrypoint because it handles
# both the python web server and the kiosk browser (cage + chromium).
cat > "$UNIT_FILE" <<EOF
[Unit]
Description=GlassDeck UI Kiosk
After=network.target

[Service]
Type=simple
WorkingDirectory=$ROOT_DIR
ExecStart=$ROOT_DIR/scripts/restart-surface.sh
Restart=always
RestartSec=10
# Environment=DISPLAY=:0 # Might be needed depending on the Wayland/X11 setup

[Install]
WantedBy=default.target
EOF

echo "Reloading systemd configuration..."
systemctl --user daemon-reload

echo "Enabling GlassDeck UI service..."
systemctl --user enable glassdeck-ui.service

echo "Ensuring linger is enabled for $USER..."
loginctl enable-linger "$USER"

echo "Success! The GlassDeck UI will now start automatically on boot."
echo "To start it now: systemctl --user start glassdeck-ui"
