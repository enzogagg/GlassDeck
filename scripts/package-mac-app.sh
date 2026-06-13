#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/dist/GlassDeck.app"
EXECUTABLE="$ROOT_DIR/mac-app/.build/release/GlassDeckMacApp"

cd "$ROOT_DIR/mac-app"
swift build -c release

rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

cp "$EXECUTABLE" "$APP_DIR/Contents/MacOS/GlassDeck"

cat > "$APP_DIR/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>GlassDeck</string>
  <key>CFBundleIdentifier</key>
  <string>ovh.ega.glassdeck.mac-app</string>
  <key>CFBundleName</key>
  <string>GlassDeck</string>
  <key>CFBundleDisplayName</key>
  <string>GlassDeck</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>15.0</string>
</dict>
</plist>
PLIST

echo "$APP_DIR"
