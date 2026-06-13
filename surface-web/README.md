# GlassDeck Surface Web

Touch-first Surface interface for GlassDeck.

The current home screen is intentionally blank. It only shows a macOS-inspired
horizontal system bar and a floating control center.

The bar surfaces the Mac daemon connection state plus live Mac CPU, RAM, and
temperature metrics, alongside the Surface battery and clock.

If the Mac and Surface have already been paired and trusted once, the launcher
tries to reconnect Bluetooth PAN automatically at startup.

The first validation happens from the Surface control center: scan Bluetooth,
select the Mac, then GlassDeck pairs, trusts, and connects it.

Daemon discovery is automatic after that: Bluetooth PAN is preferred, and the
Surface bridge also checks the local network for a reachable Mac daemon.

## Run Locally

From the repository root:

```sh
./scripts/run-surface.sh
```

Open:

```text
http://127.0.0.1:8090
```

Or from this directory:

```sh
python3 server.py
```

Use `server.py` instead of `python3 -m http.server` when you need Surface
status, hardware controls, battery data, or Bluetooth PAN daemon discovery.

## Surface Requirements

On Ubuntu:

```sh
sudo apt update
sudo apt install -y python3 chromium-browser bluez
sudo systemctl enable --now bluetooth
```

If Chromium is packaged as `chromium` on your distribution, install that package
instead and adjust the kiosk launch command if needed.

The Surface bridge uses `bluetoothctl` internally to make the deck pairable,
scan devices, trust the Mac, and reconnect it later.

## Surface Kiosk

On the Surface:

```sh
./scripts/run-surface.sh
chromium --kiosk http://127.0.0.1:8090
```

When no working URL is stored, the Surface bridge discovers the Mac daemon over
Bluetooth PAN or the local network automatically.

## Control Center

The control center currently shows:

- Mac daemon connection state.
- Target daemon host/IP.
- Bluetooth scan, one-time Mac validation, and reconnect state.
- Mac CPU, RAM, and temperature snapshot.
- Surface battery, when the browser exposes the Battery Status API.
- Local UI brightness dimming.
- Placeholder volume state.
- Quick actions for daemon ping and opening Applications on the Mac.

Direct Surface hardware brightness and volume control will need a Linux-side
bridge later. A plain browser cannot reliably change those OS settings.
