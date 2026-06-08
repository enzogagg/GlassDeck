#!/usr/bin/env sh
set -eu

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
PORT="${GLASSDECK_SURFACE_WEB_PORT:-8090}"

cd "$ROOT_DIR/surface-web"
exec python3 -m http.server "$PORT"
