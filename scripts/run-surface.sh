#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"

if command -v bluetoothctl >/dev/null 2>&1; then
  python3 "$ROOT_DIR/scripts/ensure-bluetooth-pan.py" >/dev/null 2>&1 || true
fi

exec "$ROOT_DIR/scripts/run-surface-web.sh"
