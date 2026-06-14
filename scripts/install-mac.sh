#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
LABEL="ovh.ega.glassdeck.mac-daemon"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$PLIST_DIR/$LABEL.plist"
APP_SUPPORT_DIR="$HOME/Library/Application Support/GlassDeck"
DAEMON_BIN="$APP_SUPPORT_DIR/glassdeck-mac-daemon"
LOG_DIR="$HOME/Library/Logs/GlassDeck"

if ! command -v swift >/dev/null 2>&1; then
  echo "Swift is not installed. Install Xcode Command Line Tools first: xcode-select --install" >&2
  exit 1
fi

mkdir -p "$PLIST_DIR" "$APP_SUPPORT_DIR" "$LOG_DIR"

echo "Building Mac daemon release binary..."
swift build -c release --package-path "$ROOT_DIR/mac-daemon"

echo "Installing daemon binary into Application Support..."
cp "$ROOT_DIR/mac-daemon/.build/release/glassdeck-mac-daemon" "$DAEMON_BIN"
chmod 755 "$DAEMON_BIN"

cat > "$PLIST_FILE" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$DAEMON_BIN</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$APP_SUPPORT_DIR</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>GLASSDECK_MAC_DAEMON_ADDR</key>
    <string>0.0.0.0:7878</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$LOG_DIR/mac-daemon.out.log</string>
  <key>StandardErrorPath</key>
  <string>$LOG_DIR/mac-daemon.err.log</string>
</dict>
</plist>
EOF

chmod 644 "$PLIST_FILE"

launchctl bootout "gui/$(id -u)" "$PLIST_FILE" >/dev/null 2>&1 || true
launchctl bootstrap "gui/$(id -u)" "$PLIST_FILE"
launchctl enable "gui/$(id -u)/$LABEL"
launchctl kickstart -k "gui/$(id -u)/$LABEL"

sleep 1
if command -v curl >/dev/null 2>&1; then
  if ! curl -fsS "http://127.0.0.1:7878/dashboards/main" >/dev/null; then
    echo "Warning: daemon started, but the dashboard endpoint is not reachable yet." >&2
    echo "Check logs: $LOG_DIR/mac-daemon.err.log" >&2
  fi
fi

if command -v brew >/dev/null 2>&1 && ! command -v osx-cpu-temp >/dev/null 2>&1; then
  echo "Installing optional osx-cpu-temp sensor helper..."
  brew install osx-cpu-temp || true
fi

echo "GlassDeck Mac daemon installed."
echo "Status: launchctl print gui/$(id -u)/$LABEL"
echo "Logs:   tail -f $LOG_DIR/mac-daemon.out.log $LOG_DIR/mac-daemon.err.log"
