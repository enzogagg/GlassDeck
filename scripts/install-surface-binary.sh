#!/usr/bin/env bash
set -euo pipefail

APP_NAME="glassdeck"
BIN_NAME="surface-client"
COMMAND_NAME="glassdeck-surface"
SERVICE_NAME="glassdeck-surface.service"

PACKAGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURRENT_USER="${USER:-$(id -un)}"
INSTALL_PREFIX="${GLASSDECK_INSTALL_PREFIX:-$HOME/.local/opt/$APP_NAME}"
BIN_DIR="$INSTALL_PREFIX/bin"
USER_BIN_DIR="$HOME/.local/bin"
SYSTEMD_USER_DIR="$HOME/.config/systemd/user"

usage() {
  cat <<USAGE
Usage: $0 [--no-start] [--enable-linger]

Installs a prebuilt GlassDeck Surface client package for the current user.

Options:
  --no-start       Enable autostart but do not start the service now.
  --enable-linger  Allow the user service to start at boot before login.
USAGE
}

START=1
ENABLE_LINGER=0

while [[ $# -gt 0 ]]; do
  case "$1" in
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

SOURCE_BIN="$PACKAGE_DIR/bin/$BIN_NAME"
SOURCE_SERVICE="$PACKAGE_DIR/systemd/$SERVICE_NAME"

if [[ ! -x "$SOURCE_BIN" ]]; then
  echo "Missing package binary: $SOURCE_BIN" >&2
  exit 1
fi

if [[ ! -f "$SOURCE_SERVICE" ]]; then
  echo "Missing systemd service: $SOURCE_SERVICE" >&2
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

install -m 0644 "$SOURCE_SERVICE" "$SYSTEMD_USER_DIR/$SERVICE_NAME"

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
GlassDeck Surface client installed from package.

Command:
  $USER_BIN_DIR/$COMMAND_NAME

Service:
  systemctl --user status $SERVICE_NAME

Autostart is enabled for the current user.
EOF
