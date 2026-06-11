# GlassDeck

GlassDeck is a macOS + Surface control dashboard.

The project now uses a native Swift stack on the Mac and a touch-first web
interface on the Surface:

- `mac-daemon`: Swift daemon exposing the local command API.
- `mac-app`: SwiftUI control center for macOS.
- `surface-web`: HTML/CSS/JavaScript kiosk interface for the Surface.
- `scripts`: local development launch helpers.

## Requirements

- macOS with Swift 6 and Xcode command line tools for `mac-daemon` and `mac-app`.
- Python 3 or any static file server for `surface-web`.
- Chromium or another kiosk-capable browser on the Surface.

## Development

Build the Mac daemon:

```sh
cd mac-daemon
swift build
```

Build the Mac app:

```sh
cd mac-app
swift build
```

Run the Mac daemon:

```sh
./scripts/run-mac-daemon.sh
```

Run the Surface web UI locally:

```sh
./scripts/run-surface.sh
```

Then open:

```text
http://127.0.0.1:8090
```

On the Surface, run the UI full-screen:

```sh
./scripts/run-surface.sh
chromium --kiosk http://127.0.0.1:8090
```

## Bluetooth Connectivity (Offline Mode)

You can use GlassDeck without a Wi-Fi network by using Bluetooth PAN (Personal Area Network).

### 1. On your Mac
- Go to **System Settings > General > Sharing**.
- Enable **Internet Sharing**.
- Share your connection from: (Any) to computers using: **Bluetooth PAN**.
- In **System Settings > Bluetooth**, ensure the Surface is paired.

### 2. On the Surface
- Pair with the Mac via Bluetooth.
- Connect to the Mac's Network service (PAN).
- The Mac will typically act as the gateway (e.g., `192.168.2.1`).

### 3. Start GlassDeck
Run the Mac daemon normally. It listens on all local interfaces by default,
including the Bluetooth PAN interface:

```sh
./scripts/run-mac-daemon.sh
```

Start or restart the Surface UI. The Surface web bridge detects Bluetooth PAN
interfaces such as `bnep0`, probes the usual Mac PAN gateway addresses, and
automatically points the UI at the first reachable daemon.

If you want to force a specific Mac Bluetooth IP, set it manually in Chromium:

```js
localStorage.setItem("glassdeck-daemon-url", "http://192.168.2.1:7878");
```

## Service Installation (Surface)

GlassDeck includes a modular system to install services that launch automatically on boot.

### 1. Auto-start the Web Interface

To make the kiosk UI launch automatically when the Surface boots:

```bash
./scripts/install-ui.sh
```

### 2. Enable Boot Persistence (Background Services)

A service is a directory containing a `start.sh` script. To install it:

```bash
./scripts/install-service.sh ./services/my-addon
```

This creates a `systemd` user service named `glassdeck-my-addon`.

### 3. Manage Services

- **Status:** `systemctl --user status glassdeck-<name>`
- **Logs:** `journalctl --user -u glassdeck-<name> -f`
- **Restart:** `systemctl --user restart glassdeck-<name>`

## Mac Daemon

The daemon listens on `0.0.0.0:7878` by default so the Surface can reach it over
Wi-Fi or Bluetooth PAN. Override the bind setting
with:

```sh
GLASSDECK_MAC_DAEMON_ADDR=127.0.0.1:9000 ./scripts/run-mac-daemon.sh
```

HTTP endpoints:

- `GET /status`: daemon uptime, connected clients, and available actions.
- `POST /command`: execute an action request.

Current action IDs:

- `ping`: test connectivity.
- `status`: return a compact status message.
- `open-url`: open an `http` or `https` URL.
- `open-applications`: open the macOS Applications folder.

## Surface Web

The Surface UI is intentionally minimal for now: a blank home surface with a
macOS-style horizontal system bar. The bar shows daemon connectivity, the target
machine host/IP, Surface battery when supported by the browser, and a clock.

The control center button opens quick controls for:

- Mac daemon status and refresh.
- Target daemon host/IP.
- Surface battery state.
- Local UI brightness dimming.
- Placeholder volume state.
- Quick Mac actions.

Serve it locally and launch it full-screen:

```sh
chromium --kiosk http://127.0.0.1:8090
```

When the daemon runs on another machine, set the URL in browser local storage:

```js
localStorage.setItem("glassdeck-daemon-url", "http://<mac-ip>:7878");
```

When no URL is stored, the Surface bridge tries to discover the Mac daemon over
Bluetooth PAN automatically and shows the selected target in the control center.

Browser limitations:

- The battery value depends on `navigator.getBattery()` support.
- Direct hardware brightness and volume control need a Linux-side bridge later;
  the current brightness control dims the web UI locally.

## Repository Hygiene

Generated build directories are ignored:

- `.build/`
- `target/`
- `dist/`
- editor, OS, log, and local agent metadata
