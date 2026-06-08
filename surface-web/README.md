# GlassDeck Surface Web

Touch-first Surface interface for GlassDeck.

The current home screen is intentionally blank. It only shows a macOS-inspired
horizontal system bar and a floating control center.

## Run Locally

From the repository root:

```sh
./scripts/run-surface-web.sh
```

Open:

```text
http://127.0.0.1:8090
```

Or from this directory:

```sh
python3 -m http.server 8090
```

## Surface Kiosk

On the Surface:

```sh
./scripts/run-surface-web.sh
chromium --kiosk http://127.0.0.1:8090
```

Set the Mac daemon URL when the daemon runs on another machine:

```js
localStorage.setItem("glassdeck-daemon-url", "http://<mac-ip>:7878");
```

## Control Center

The control center currently shows:

- Mac daemon connection state.
- Target daemon host/IP.
- Surface battery, when the browser exposes the Battery Status API.
- Local UI brightness dimming.
- Placeholder volume state.
- Quick actions for daemon ping and opening Applications on the Mac.

Direct Surface hardware brightness and volume control will need a Linux-side
bridge later. A plain browser cannot reliably change those OS settings.
