# GlassDeck Surface Web

Touch-first Surface interface for GlassDeck.

The current home screen is intentionally blank. It only shows a macOS-inspired
horizontal system bar and a floating control center.

The bar surfaces the Mac daemon connection state plus live Mac CPU, RAM, and
temperature metrics, alongside the Surface battery and clock.

If the Mac and Surface have already been paired and trusted once, the launcher
tries to reconnect Bluetooth PAN automatically at startup.

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

To make the Surface visible to the Mac:

```sh
bluetoothctl
```

Inside `bluetoothctl`:

```text
power on
agent on
default-agent
pairable on
discoverable on
```

## Surface Kiosk

On the Surface:

```sh
./scripts/run-surface.sh
chromium --kiosk http://127.0.0.1:8090
```

Set the Mac daemon URL when the daemon runs on another machine:

```js
localStorage.setItem("glassdeck-daemon-url", "http://<mac-ip>:7878");
```

When no URL is stored, the Surface bridge tries to discover the Mac daemon over
Bluetooth PAN automatically.

## Control Center

The control center currently shows:

- Mac daemon connection state.
- Target daemon host/IP.
- Mac CPU, RAM, and temperature snapshot.
- Surface battery, when the browser exposes the Battery Status API.
- Local UI brightness dimming.
- Placeholder volume state.
- Quick actions for daemon ping and opening Applications on the Mac.

Direct Surface hardware brightness and volume control will need a Linux-side
bridge later. A plain browser cannot reliably change those OS settings.
