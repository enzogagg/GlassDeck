#!/usr/bin/env bash
set -euo pipefail

APP_NAME="glassdeck-surface"
BIN_NAME="surface-client"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="$(sed -n 's/^version = "\(.*\)"/\1/p' "$ROOT_DIR/surface-client/Cargo.toml" | head -n 1)"
TARGET_ARCH="$(uname -m)"
DIST_DIR="$ROOT_DIR/dist"
PACKAGE_DIR="$DIST_DIR/$APP_NAME-$VERSION-$TARGET_ARCH"
ARCHIVE="$DIST_DIR/$APP_NAME-$VERSION-$TARGET_ARCH.tar.gz"

if [[ -z "$VERSION" ]]; then
  echo "Unable to read version from surface-client/Cargo.toml" >&2
  exit 1
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "Surface packages should be built on Linux for the target device." >&2
  exit 1
fi

command -v cargo >/dev/null 2>&1 || {
  echo "cargo is required to build the package." >&2
  exit 1
}

cargo build --release --package "$BIN_NAME"

rm -rf "$PACKAGE_DIR" "$ARCHIVE"
mkdir -p "$PACKAGE_DIR/bin" "$PACKAGE_DIR/systemd"

install -m 0755 "$ROOT_DIR/target/release/$BIN_NAME" "$PACKAGE_DIR/bin/$BIN_NAME"
install -m 0755 "$ROOT_DIR/scripts/install-surface-binary.sh" "$PACKAGE_DIR/install.sh"
install -m 0644 "$ROOT_DIR/packaging/systemd/glassdeck-surface.service" \
  "$PACKAGE_DIR/systemd/glassdeck-surface.service"

cat > "$PACKAGE_DIR/README.txt" <<EOF
GlassDeck Surface package $VERSION ($TARGET_ARCH)

Install:
  ./install.sh

Install without starting now:
  ./install.sh --no-start

Install and allow startup before login:
  ./install.sh --enable-linger

Check status:
  systemctl --user status glassdeck-surface.service

Uninstall from a source checkout:
  scripts/uninstall-surface.sh
EOF

(
  cd "$DIST_DIR"
  tar -czf "$ARCHIVE" "$(basename "$PACKAGE_DIR")"
)

echo "Package created: $ARCHIVE"
