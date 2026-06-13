#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)"

if ! command -v apt-get >/dev/null 2>&1; then
  echo "This installer currently supports Ubuntu/Debian systems with apt-get." >&2
  exit 1
fi

install_packages() {
  local packages=(
    python3
    bluez
    cage
    brightnessctl
    wireplumber
    pulseaudio-utils
    alsa-utils
    dbus-user-session
  )

  echo "Refreshing package metadata..."
  sudo apt-get update

  if apt-cache show chromium >/dev/null 2>&1; then
    packages+=(chromium)
  elif apt-cache show chromium-browser >/dev/null 2>&1; then
    packages+=(chromium-browser)
  else
    echo "No Chromium apt package found. Install chromium or chromium-browser manually." >&2
    exit 1
  fi

  echo "Installing Surface packages..."
  sudo apt-get install -y "${packages[@]}"
}

enable_bluetooth() {
  echo "Enabling Bluetooth..."
  sudo systemctl enable --now bluetooth
}

install_kiosk_service() {
  echo "Installing GlassDeck kiosk service..."
  "$ROOT_DIR/scripts/install-ui.sh"
}

start_kiosk_service() {
  echo "Starting GlassDeck kiosk service..."
  systemctl --user daemon-reload
  systemctl --user restart glassdeck-ui.service
}

install_packages
enable_bluetooth
install_kiosk_service
start_kiosk_service

echo "GlassDeck Surface installation complete."
echo "Status: systemctl --user status glassdeck-ui.service"
