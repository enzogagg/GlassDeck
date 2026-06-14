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
- Ubuntu 24.04 or another Linux distribution on the Surface.
- Python 3 for the Surface web bridge.
- Chromium or another kiosk-capable browser on the Surface.
- BlueZ on the Surface for Bluetooth pairing and Bluetooth PAN.

## Installation

### 1. Clone the project

On both the Mac and the Surface:

```sh
git clone https://gitea.ega.ovh/enzogagg/GlassDeck.git
cd GlassDeck
```

If the repository already exists:

```sh
cd GlassDeck
git pull
```

### 2. Install the Mac daemon and app

Install Apple's command line tools if Swift is not available:

```sh
xcode-select --install
```

Then install the LaunchAgent:

```sh
./scripts/install-mac.sh
```

This creates `~/Library/LaunchAgents/ovh.ega.glassdeck.mac-daemon.plist`,
starts the daemon at login, and keeps it alive.

### 3. Install the Surface deck

On Ubuntu, run the Surface bootstrap from the cloned repository:

```sh
./scripts/install-surface.sh
```

This installs the Surface packages, enables Bluetooth, installs the user
systemd service, and starts the kiosk.

### 4. Pair once from the Surface deck

Start the Surface UI, open the control center, use the Bluetooth scan button,
then select the Mac once. GlassDeck powers on Bluetooth, makes the Surface
pairable/discoverable, pairs the Mac, marks it trusted, and connects it.

After that first validation, GlassDeck retries the PAN connection automatically
at startup.

If Bluetooth PAN is slow or unavailable, the Surface bridge also discovers a
reachable GlassDeck Mac daemon on the local network automatically.

### 5. Enable Bluetooth PAN on the Mac

On macOS:

- Open **System Settings > Bluetooth** and confirm the Surface is paired.
- Open **System Settings > General > Sharing**.
- Enable **Internet Sharing**.
- Share your connection from any available interface.
- Share to computers using **Bluetooth PAN**.

The Mac usually becomes the Bluetooth PAN gateway at `192.168.2.1`.

Back on the Surface, confirm that Linux created a Bluetooth network interface:

```sh
ip addr show
```

Look for an interface such as `bnep0`. GlassDeck uses this interface to find
the Mac daemon without Wi-Fi. The launcher will try to reconnect paired devices
automatically before starting the kiosk. If the Mac is on the same LAN, the
Surface bridge can also find `:7878` directly.

### 6. Start GlassDeck

On the Mac:

```sh
./scripts/install-mac.sh
```

On the Surface:

```sh
./scripts/run-surface.sh
```

Open the Surface UI:

```text
http://127.0.0.1:8090
```

For kiosk boot on the Surface, use the full installer:

```sh
./scripts/install-surface.sh
```

When Bluetooth PAN is connected, GlassDeck automatically probes the Mac daemon
over Bluetooth and shows a `BT` target in the control center.

If the Surface was already running before Bluetooth PAN connected, restart the
UI:

```sh
systemctl --user restart glassdeck-ui.service
```

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

Run the Mac configuration app:

```sh
./scripts/run-mac-app.sh
```

Equivalent Swift command from the repository root:

```sh
swift run GlassDeckMacApp
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

Manage the installed LaunchAgent:

```sh
./scripts/mac-daemon-service.sh status
./scripts/mac-daemon-service.sh restart
./scripts/mac-daemon-service.sh stop
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
machine host/IP, Mac CPU/RAM/temperature metrics, Surface battery when supported
by the browser, and a clock.

The control center button opens quick controls for:

- Mac daemon status and refresh.
- Target daemon host/IP.
- Installation status, Bluetooth status, and Mac discovery status.
- Bluetooth scan, reconnect, and forget controls.
- Mac CPU, RAM, and temperature snapshot.
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
- Mac temperature is shown when the daemon can read it from a local sensor tool
  such as `osx-cpu-temp`; otherwise it stays unavailable.
- Direct hardware brightness and volume control need a Linux-side bridge later;
  the current brightness control dims the web UI locally.

## Repository Hygiene

Generated build directories are ignored:

- `.build/`
- `target/`
- `dist/`
- editor, OS, log, and local agent metadata
