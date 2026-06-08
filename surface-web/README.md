# GlassDeck Surface Web

Touch-first Surface interface for GlassDeck.

This app is intentionally static for now: it can run from a local file or from a
tiny HTTP server, then be launched full-screen by Chromium on the Surface.

## Run Locally

From this directory:

```sh
python3 -m http.server 8080
```

Open:

```text
http://127.0.0.1:8080
```

The UI expects the Mac daemon API at:

```text
http://127.0.0.1:7878
```

On the Surface, set the daemon URL in browser local storage if the Mac is on
another host:

```js
localStorage.setItem("glassdeck-daemon-url", "http://<mac-ip>:7878");
```

## Surface Kiosk Direction

The target installation flow is:

```sh
chromium --kiosk http://127.0.0.1:8080
```

Later this can become a packaged PWA or a Vite/React app if the action editor
needs richer state management.
