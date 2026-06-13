#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
CHROMIUM_BIN="${GLASSDECK_CHROMIUM_BIN:-}"

if [ -z "$CHROMIUM_BIN" ]; then
  if command -v chromium >/dev/null 2>&1; then
    CHROMIUM_BIN="chromium"
  elif command -v chromium-browser >/dev/null 2>&1; then
    CHROMIUM_BIN="chromium-browser"
  elif command -v google-chrome >/dev/null 2>&1; then
    CHROMIUM_BIN="google-chrome"
  else
    echo "No Chromium-compatible browser found. Install chromium or chromium-browser." >&2
    exit 1
  fi
fi

if ! command -v cage >/dev/null 2>&1; then
  echo "cage is not installed. Run ./scripts/install-surface.sh first." >&2
  exit 1
fi

echo "Stopping existing GlassDeck processes..."
pkill -f "python3 -m http.server 8090" || true
pkill -f "GlassDeck/surface-web/server.py" || true
pkill -f "cage -- chromium" || true
pkill -f "cage -- chromium-browser" || true
pkill -f "cage -- google-chrome" || true

echo "Starting Web Server..."
"$ROOT_DIR/scripts/run-surface.sh" &
sleep 2

echo "Launching Kiosk Mode..."
exec cage -- "$CHROMIUM_BIN" \
  --kiosk \
  --incognito \
  --disable-cache \
  --disable-translate \
  --disable-features=Translate,TranslateUI \
  --disk-cache-size=1 \
  --media-cache-size=1 \
  --lang=fr-FR \
  http://localhost:8090
