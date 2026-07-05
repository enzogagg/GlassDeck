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

On Ubuntu, from the repository root:

```sh
./scripts/install-surface.sh
```

The installer pulls the required packages, enables Bluetooth, installs the user
service, and starts the kiosk.

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

- Installation status.
- Mac daemon connection state.
- Target daemon host/IP.
- Bluetooth scan, one-time Mac validation, reconnect state, and forget control.
- Mac CPU, RAM, and temperature snapshot.
- Surface battery, when the browser exposes the Battery Status API.
- Local UI brightness dimming.
- Placeholder volume state.
- Quick actions for daemon ping and opening Applications on the Mac.

Direct Surface hardware brightness and volume control will need a Linux-side
bridge later. A plain browser cannot reliably change those OS settings.
