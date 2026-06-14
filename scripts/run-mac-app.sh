#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"

if [ "${1:-}" = "--foreground" ]; then
  cd "$ROOT_DIR/mac-app"
  exec swift run GlassDeckMacApp
fi

APP_DIR="$("$ROOT_DIR/scripts/package-mac-app.sh" | tail -n 1)"
open "$APP_DIR"

echo "GlassDeck Mac app launched: $APP_DIR"
echo "Use '$0 --foreground' only when you want the terminal attached to app logs."
