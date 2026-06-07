#!/usr/bin/env bash
set -euo pipefail

APP_NAME="glassdeck"
BIN_NAME="surface-client"
COMMAND_NAME="glassdeck-surface"
SERVICE_NAME="glassdeck-surface.service"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT_USER="${USER:-$(id -un)}"
INSTALL_PREFIX="${GLASSDECK_INSTALL_PREFIX:-$HOME/.local/opt/$APP_NAME}"
BIN_DIR="$INSTALL_PREFIX/bin"
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

usage() {
  cat <<USAGE
Usage: $0 [--no-build] [--no-start] [--enable-linger]

Installs the GlassDeck Surface client for the current Linux user and enables
automatic startup with systemd user services.

Options:
  --no-build       Use an existing target/release/$BIN_NAME binary.
  --no-start       Enable autostart but do not start the service now.
  --enable-linger  Allow the user service to start at boot before login.

Environment:
  GLASSDECK_INSTALL_PREFIX  Override install prefix.
                             Default: $INSTALL_PREFIX
USAGE
}

BUILD=1
START=1
ENABLE_LINGER=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --no-build)
      BUILD=0
      shift
      ;;
    --no-start)
      START=0
      shift
      ;;
    --enable-linger)
      ENABLE_LINGER=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This installer is intended for Linux Surface devices." >&2
  exit 1
fi

if ! command -v systemctl >/dev/null 2>&1; then
  echo "systemctl is required to enable automatic startup." >&2
  exit 1
fi

for group_name in video input render; do
  if getent group "$group_name" >/dev/null 2>&1 && ! id -nG "$CURRENT_USER" | tr ' ' '\n' | grep -qx "$group_name"; then
    echo "Warning: user '$CURRENT_USER' is not in group '$group_name'." >&2
    echo "The linuxkms backend may need access to that group on this device." >&2
  fi
done

if [[ "$BUILD" -eq 1 ]]; then
  if ! command -v cargo >/dev/null 2>&1; then
    echo "cargo is required to build from source. Install Rust or use --no-build." >&2
    exit 1
  fi

  cargo build --release --package "$BIN_NAME"
fi

SOURCE_BIN="$ROOT_DIR/target/release/$BIN_NAME"
if [[ ! -x "$SOURCE_BIN" ]]; then
  echo "Missing executable: $SOURCE_BIN" >&2
  echo "Run without --no-build or provide a release binary first." >&2
  exit 1
fi

mkdir -p "$BIN_DIR" "$USER_BIN_DIR" "$SYSTEMD_USER_DIR"
install -m 0755 "$SOURCE_BIN" "$BIN_DIR/$BIN_NAME"

cat > "$USER_BIN_DIR/$COMMAND_NAME" <<EOF
#!/usr/bin/env bash
set -euo pipefail
exec "$BIN_DIR/$BIN_NAME" "\$@"
EOF
chmod 0755 "$USER_BIN_DIR/$COMMAND_NAME"

install -m 0644 "$ROOT_DIR/packaging/systemd/$SERVICE_NAME" "$SYSTEMD_USER_DIR/$SERVICE_NAME"

systemctl --user daemon-reload
systemctl --user enable "$SERVICE_NAME"

if [[ "$ENABLE_LINGER" -eq 1 ]]; then
  if command -v loginctl >/dev/null 2>&1; then
    loginctl enable-linger "$CURRENT_USER" || {
      echo "Warning: failed to enable linger for '$CURRENT_USER'." >&2
      echo "Run manually if needed: loginctl enable-linger $CURRENT_USER" >&2
    }
  else
    echo "Warning: loginctl is unavailable; cannot enable linger." >&2
  fi
fi

if [[ "$START" -eq 1 ]]; then
  systemctl --user restart "$SERVICE_NAME"
fi

cat <<EOF
GlassDeck Surface client installed.

Command:
  $USER_BIN_DIR/$COMMAND_NAME

Service:
  systemctl --user status $SERVICE_NAME

Autostart is enabled for the current user.
EOF
