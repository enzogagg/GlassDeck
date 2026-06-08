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
./scripts/run-surface-web.sh
```

Then open:

```text
http://127.0.0.1:8090
```

## Mac Daemon

The daemon listens on `127.0.0.1:7878` by default. Override the bind setting
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

The Surface UI is intentionally static for now. It can be served locally and
launched full-screen:

```sh
chromium --kiosk http://127.0.0.1:8090
```

When the daemon runs on another machine, set the URL in browser local storage:

```js
localStorage.setItem("glassdeck-daemon-url", "http://<mac-ip>:7878");
```

## Repository Hygiene

Generated build directories are ignored:

- `.build/`
- `target/`
- `dist/`
- editor, OS, log, and local agent metadata
