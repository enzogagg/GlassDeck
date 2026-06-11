#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"

echo "Stopping existing GlassDeck processes..."
pkill -f "python3 -m http.server 8090" || true
pkill -f "GlassDeck/surface-web/server.py" || true
pkill -f "cage -- chromium" || true

echo "Starting Web Server..."
"$ROOT_DIR/scripts/run-surface.sh" &
sleep 2

echo "Launching Kiosk Mode..."
exec cage -- chromium \
  --kiosk \
  --incognito \
  --disable-cache \
  --disable-translate \
  --disable-features=Translate,TranslateUI \
  --disk-cache-size=1 \
  --media-cache-size=1 \
  --lang=fr-FR \
  http://localhost:8090
