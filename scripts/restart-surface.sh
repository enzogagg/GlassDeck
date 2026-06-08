#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"

echo "Stopping existing GlassDeck processes..."
pkill -f "python3 -m http.server 8090" || true
pkill -f "cage -- chromium" || true

echo "Starting Web Server..."
"$ROOT_DIR/scripts/run-surface.sh" &
sleep 2

echo "Launching Kiosk Mode..."
exec cage -- chromium --kiosk --incognito --disable-cache --disk-cache-size=1 --media-cache-size=1 http://localhost:8090
