#!/usr/bin/env bash
set -euo pipefail

# GlassDeck Service Installer
# Installs a directory as a systemd user service.

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <package-directory> [service-name]"
    exit 1
fi

PACKAGE_DIR=$(realpath "$1")
PACKAGE_NAME=$(basename "$PACKAGE_DIR")
SERVICE_NAME=${2:-$PACKAGE_NAME}
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
UNIT_FILE="$SYSTEMD_USER_DIR/glassdeck-$SERVICE_NAME.service"

if [ ! -d "$PACKAGE_DIR" ]; then
    echo "Error: Directory '$PACKAGE_DIR' not found."
    exit 1
fi

if [ ! -f "$PACKAGE_DIR/start.sh" ]; then
    echo "Error: '$PACKAGE_DIR/start.sh' not found. Each package must have a start.sh script."
    exit 1
fi

if [ ! -x "$PACKAGE_DIR/start.sh" ]; then
    echo "Warning: Making '$PACKAGE_DIR/start.sh' executable..."
    chmod +x "$PACKAGE_DIR/start.sh"
fi

echo "Installing service: glassdeck-$SERVICE_NAME"
echo "Package directory: $PACKAGE_DIR"

mkdir -p "$SYSTEMD_USER_DIR"

cat > "$UNIT_FILE" <<EOF
[Unit]
Description=GlassDeck Service - $SERVICE_NAME
After=network.target

[Service]
Type=simple
WorkingDirectory=$PACKAGE_DIR
ExecStart=$PACKAGE_DIR/start.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=default.target
EOF

echo "Reloading systemd configuration..."
systemctl --user daemon-reload

echo "Enabling and starting service..."
systemctl --user enable "glassdeck-$SERVICE_NAME.service"
systemctl --user start "glassdeck-$SERVICE_NAME.service"

echo "Success! Service 'glassdeck-$SERVICE_NAME' is installed and active."
echo "View status: systemctl --user status glassdeck-$SERVICE_NAME"
echo "View logs:   journalctl --user -u glassdeck-$SERVICE_NAME -f"
