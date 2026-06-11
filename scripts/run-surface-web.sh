#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
PORT="${GLASSDECK_SURFACE_WEB_PORT:-8090}"

export GLASSDECK_SURFACE_WEB_PORT="$PORT"
exec python3 "$ROOT_DIR/surface-web/server.py"
