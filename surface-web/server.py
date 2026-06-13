#!/usr/bin/env python3
import json
import mimetypes
import os
import shutil
import socket
import subprocess
import time
import urllib.error
import urllib.request
from concurrent.futures import ThreadPoolExecutor, as_completed
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parent
DAEMON_PORT = int(os.environ.get("GLASSDECK_MAC_DAEMON_PORT", "7878"))
DAEMON_PROBE_TTL_SECONDS = 5
DAEMON_LAN_SCAN_TTL_SECONDS = 30
_daemon_probe_cache = {"timestamp": 0.0, "value": None}
_bluetooth_scan_cache = {"timestamp": 0.0, "devices": []}
_lan_scan_cache = {"timestamp": 0.0, "candidates": []}


def local_ipv4_addresses():
    addresses = []

    try:
        output = subprocess.check_output(
            ["hostname", "-I"],
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=1,
        )
        addresses.extend(output.split())
    except (OSError, subprocess.SubprocessError):
        pass

    try:
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
            sock.connect(("1.1.1.1", 80))
            addresses.append(sock.getsockname()[0])
    except OSError:
        pass

    filtered = []
    for address in addresses:
        if ":" in address or address.startswith("127."):
            continue
        if address not in filtered:
            filtered.append(address)

    return filtered


def bluetooth_daemon_snapshot():
    now = time.monotonic()
    if _daemon_probe_cache["value"] is not None and now - _daemon_probe_cache["timestamp"] < DAEMON_PROBE_TTL_SECONDS:
        return _daemon_probe_cache["value"]

    interfaces = bluetooth_interfaces()
    candidates = daemon_candidates(interfaces)
    candidates.extend(lan_daemon_candidates())
    recommended = None

    for candidate in candidates:
        candidate["reachable"] = daemon_reachable(candidate["url"])
        if candidate["reachable"] and recommended is None:
            recommended = candidate["url"]

    if recommended is None and candidates:
        recommended = candidates[0]["url"]

    snapshot = {
        "interfaces": interfaces,
        "candidates": candidates,
        "devices": bluetooth_devices(),
        "ready": bluetooth_ready(),
        "recommended_url": recommended,
    }
    _daemon_probe_cache["timestamp"] = now
    _daemon_probe_cache["value"] = snapshot
    return snapshot


def bluetooth_ready():
    return shutil.which("bluetoothctl") is not None


def bluetooth_devices():
    if not bluetooth_ready():
        return []

    devices = {}
    for kind in ("", "Paired", "Trusted", "Connected"):
        args = ["bluetoothctl", "devices"]
        if kind:
            args.append(kind)

        for line in command_lines(args, timeout=2):
            parts = line.strip().split(maxsplit=2)
            if len(parts) < 3 or parts[0] != "Device":
                continue

            address = parts[1]
            device = devices.setdefault(
                address,
                {
                    "address": address,
                    "name": parts[2],
                    "paired": False,
                    "trusted": False,
                    "connected": False,
                },
            )
            if kind == "Paired":
                device["paired"] = True
            elif kind == "Trusted":
                device["trusted"] = True
            elif kind == "Connected":
                device["connected"] = True

    for device in devices.values():
        details = bluetooth_device_info(device["address"])
        device.update(details)

    return sorted(
        devices.values(),
        key=lambda item: (
            not item.get("connected", False),
            not item.get("trusted", False),
            not is_likely_mac_device(item),
            item.get("name", "").lower(),
        ),
    )


def bluetooth_device_info(address):
    info = {
        "name": "",
        "paired": False,
        "trusted": False,
        "connected": False,
        "mac_candidate": False,
    }

    for line in command_lines(["bluetoothctl", "info", address], timeout=2):
        stripped = line.strip()
        lower = stripped.lower()
        if lower.startswith("name:"):
            info["name"] = stripped.split(":", 1)[1].strip()
        elif lower.startswith("paired:"):
            info["paired"] = "yes" in lower
        elif lower.startswith("trusted:"):
            info["trusted"] = "yes" in lower
        elif lower.startswith("connected:"):
            info["connected"] = "yes" in lower
        elif "personal area network" in lower or "network access point" in lower:
            info["mac_candidate"] = True

    if info["name"]:
        info["mac_candidate"] = info["mac_candidate"] or is_likely_mac_name(info["name"])

    return info


def is_likely_mac_device(device):
    return device.get("mac_candidate") or is_likely_mac_name(device.get("name", ""))


def is_likely_mac_name(name):
    lower = name.lower()
    return any(hint in lower for hint in ("mac", "macbook", "imac", "apple", "glassdeck"))


def command_lines(args, timeout=3):
    try:
        output = subprocess.check_output(
            args,
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=timeout,
        )
        return output.splitlines()
    except (OSError, subprocess.SubprocessError):
        return []


def prepare_bluetooth():
    if not bluetooth_ready():
        return {"ok": False, "error": "bluetoothctl indisponible"}

    _daemon_probe_cache["value"] = None
    for args in (
        ["bluetoothctl", "power", "on"],
        ["bluetoothctl", "agent", "on"],
        ["bluetoothctl", "default-agent"],
        ["bluetoothctl", "pairable", "on"],
        ["bluetoothctl", "discoverable", "on"],
    ):
        try:
            subprocess.run(args, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3, check=False)
        except (OSError, subprocess.SubprocessError):
            pass

    return {"ok": True, "bluetooth": bluetooth_daemon_snapshot()}


def scan_bluetooth():
    if not bluetooth_ready():
        return {"ok": False, "error": "bluetoothctl indisponible"}

    _daemon_probe_cache["value"] = None
    now = time.monotonic()
    if now - _bluetooth_scan_cache["timestamp"] < 12:
        return {"ok": True, "devices": _bluetooth_scan_cache["devices"]}

    try:
        subprocess.run(["bluetoothctl", "power", "on"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3, check=False)
    except (OSError, subprocess.SubprocessError):
        pass

    try:
        subprocess.run(
            ["bluetoothctl", "scan", "on"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            timeout=6,
            check=False,
        )
    except subprocess.TimeoutExpired:
        pass
    finally:
        try:
            subprocess.run(["bluetoothctl", "scan", "off"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=3, check=False)
        except (OSError, subprocess.SubprocessError):
            pass

    devices = bluetooth_devices()
    _bluetooth_scan_cache["timestamp"] = time.monotonic()
    _bluetooth_scan_cache["devices"] = devices
    return {"ok": True, "devices": devices}


def connect_bluetooth_device(address):
    if not bluetooth_ready():
        return {"ok": False, "error": "bluetoothctl indisponible"}

    if not isinstance(address, str) or not address:
        return {"ok": False, "error": "Adresse Bluetooth manquante"}

    prepare_bluetooth()
    commands = [
        ["bluetoothctl", "pair", address],
        ["bluetoothctl", "trust", address],
        ["bluetoothctl", "connect", address],
    ]

    errors = []
    for command in commands:
        try:
            subprocess.check_output(command, stderr=subprocess.STDOUT, text=True, timeout=25)
        except (OSError, subprocess.SubprocessError) as error:
            output = getattr(error, "output", None)
            if output:
                errors.append(output.strip())

    _daemon_probe_cache["value"] = None
    snapshot = bluetooth_daemon_snapshot()
    device = next((item for item in snapshot["devices"] if item["address"] == address), None)
    connected = bool(device and device.get("connected"))

    return {
        "ok": connected,
        "bluetooth": snapshot,
        "device": device,
        "error": None if connected else "; ".join(errors[-2:]) or "Connexion Bluetooth non établie",
    }


def bluetooth_interfaces():
    interfaces = []

    for entry in ip_json(["-j", "addr", "show"]) or []:
        name = entry.get("ifname", "")
        if not is_bluetooth_interface(name):
            continue

        addresses = [
            addr.get("local")
            for addr in entry.get("addr_info", [])
            if addr.get("family") == "inet" and addr.get("local")
        ]
        interfaces.append(
            {
                "name": name,
                "addresses": addresses,
                "gateway": gateway_for_interface(name),
            }
        )

    return interfaces


def daemon_candidates(interfaces):
    seen = set()
    candidates = []

    for interface in interfaces:
        hosts = [interface.get("gateway")]
        hosts.extend(common_mac_pan_hosts())

        for host in hosts:
            if not host or host in seen:
                continue
            seen.add(host)
            candidates.append(
                {
                    "host": host,
                    "interface": interface["name"],
                    "url": f"http://{host}:{DAEMON_PORT}",
                    "reachable": False,
                }
            )

    return candidates


def lan_daemon_candidates():
    now = time.monotonic()
    if now - _lan_scan_cache["timestamp"] < DAEMON_LAN_SCAN_TTL_SECONDS:
        return _lan_scan_cache["candidates"]

    hosts = []
    for address in local_ipv4_addresses():
        parts = address.split(".")
        if len(parts) != 4:
            continue

        prefix = ".".join(parts[:3])
        for host_id in range(1, 255):
            host = f"{prefix}.{host_id}"
            if host != address:
                hosts.append(host)

    candidates = []
    with ThreadPoolExecutor(max_workers=32) as executor:
        futures = {executor.submit(probe_daemon_host, host): host for host in sorted(set(hosts))}
        for future in as_completed(futures):
            candidate = future.result()
            if candidate:
                candidates.append(candidate)

    _lan_scan_cache["timestamp"] = now
    _lan_scan_cache["candidates"] = candidates
    return candidates


def probe_daemon_host(host):
    url = f"http://{host}:{DAEMON_PORT}"
    if not daemon_reachable(url, timeout=0.18):
        return None

    return {
        "host": host,
        "interface": "lan",
        "url": url,
        "reachable": True,
    }


def common_mac_pan_hosts():
    return ["192.168.2.1", "172.20.10.1"]


def is_bluetooth_interface(name):
    lower = name.lower()
    return lower.startswith("bnep") or "bluetooth" in lower or lower.startswith("pan")


def gateway_for_interface(name):
    routes = ip_json(["-j", "route", "show", "dev", name]) or []
    for route in routes:
        if route.get("gateway"):
            return route["gateway"]

    return None


def ip_json(args):
    if shutil.which("ip") is None:
        return None

    try:
        output = subprocess.check_output(
            ["ip", *args],
            stderr=subprocess.DEVNULL,
            text=True,
            timeout=1,
        )
        return json.loads(output)
    except (OSError, subprocess.SubprocessError, json.JSONDecodeError):
        return None


def daemon_reachable(base_url, timeout=0.35):
    try:
        with urllib.request.urlopen(f"{base_url}/status", timeout=timeout) as response:
            return 200 <= response.status < 300
    except (OSError, urllib.error.URLError):
        return False


def battery_snapshot():
    power_root = Path("/sys/class/power_supply")
    batteries = sorted(power_root.glob("BAT*"))
    mains = sorted(
        item
        for item in power_root.iterdir()
        if item.is_dir() and read_power_value(item, "type") in {"Mains", "USB", "USB_C"}
    )

    if not batteries:
        return None

    battery = batteries[0]

    capacity = read_power_value(battery, "capacity")
    status = read_power_value(battery, "status")
    online_values = [read_power_value(source, "online") for source in mains]
    plugged = any(value == "1" for value in online_values)

    try:
        percent = int(capacity) if capacity is not None else None
    except ValueError:
        percent = None

    charging = plugged or status in {"Charging", "Full"}

    return {
        "percent": percent,
        "charging": charging,
        "plugged": plugged,
        "status": status or "Unknown",
    }


def control_snapshot():
    return {
        "brightness": brightness_snapshot(),
        "volume": volume_snapshot(),
    }


def brightness_snapshot():
    backlights = sorted(Path("/sys/class/backlight").glob("*"))

    if not backlights:
        return {"available": False, "error": "Aucun rétroéclairage détecté"}

    backlight = backlights[0]
    current = read_power_value(backlight, "actual_brightness") or read_power_value(backlight, "brightness")
    maximum = read_power_value(backlight, "max_brightness")

    try:
        percent = round((int(current) / int(maximum)) * 100)
    except (TypeError, ValueError, ZeroDivisionError):
        percent = None

    return {
        "available": shutil.which("brightnessctl") is not None,
        "device": backlight.name,
        "percent": percent,
    }


def set_brightness(percent):
    value = clamp_percent(percent)

    if shutil.which("brightnessctl") is None:
        return {"ok": False, "error": "brightnessctl indisponible"}

    try:
        subprocess.check_output(
            ["brightnessctl", "--quiet", "set", f"{value}%"],
            stderr=subprocess.STDOUT,
            text=True,
            timeout=2,
        )
    except (OSError, subprocess.SubprocessError) as error:
        message = getattr(error, "output", None) or str(error)
        return {"ok": False, "error": message.strip()}

    return {"ok": True, "brightness": brightness_snapshot()}


def volume_snapshot():
    backend = volume_backend()
    return {
        "available": backend is not None,
        "backend": backend,
    }


def set_volume(percent):
    value = clamp_percent(percent)
    backend = volume_backend()

    if backend == "wpctl":
        command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{value / 100:.2f}"]
    elif backend == "pactl":
        command = ["pactl", "set-sink-volume", "@DEFAULT_SINK@", f"{value}%"]
    elif backend == "amixer":
        command = ["amixer", "set", "Master", f"{value}%"]
    else:
        return {"ok": False, "error": "Aucun backend volume installé (wpctl, pactl ou amixer)"}

    try:
        subprocess.check_output(command, stderr=subprocess.STDOUT, text=True, timeout=2)
    except (OSError, subprocess.SubprocessError) as error:
        message = getattr(error, "output", None) or str(error)
        return {"ok": False, "error": message.strip()}

    return {"ok": True, "volume": volume_snapshot()}


def volume_backend():
    for command in ("wpctl", "pactl", "amixer"):
        if shutil.which(command):
            return command
    return None


def clamp_percent(value):
    try:
        return max(0, min(100, round(float(value))))
    except (TypeError, ValueError):
        return 0


def read_power_value(directory, name):
    try:
        return (directory / name).read_text(encoding="utf-8").strip()
    except OSError:
        return None


class GlassDeckHandler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(ROOT_DIR), **kwargs)

    def do_GET(self):
        if self.path.split("?", 1)[0] == "/surface-status":
            self.write_json(
                {
                    "addresses": local_ipv4_addresses(),
                    "battery": battery_snapshot(),
                    "bluetooth": bluetooth_daemon_snapshot(),
                    "controls": control_snapshot(),
                }
            )
            return

        super().do_GET()

    def do_POST(self):
        path = self.path.split("?", 1)[0]
        if path not in {"/surface-control", "/bluetooth-control"}:
            self.send_error(404)
            return

        length = int(self.headers.get("Content-Length", "0"))
        try:
            payload = json.loads(self.rfile.read(length) or b"{}")
        except json.JSONDecodeError:
            self.send_error(400, "JSON invalide")
            return

        if path == "/bluetooth-control":
            action = payload.get("action")

            if action == "prepare":
                self.write_json(prepare_bluetooth())
                return

            if action == "scan":
                self.write_json(scan_bluetooth())
                return

            if action == "connect":
                self.write_json(connect_bluetooth_device(payload.get("address")))
                return

            self.send_error(400, "Action Bluetooth inconnue")
            return

        control = payload.get("control")
        value = payload.get("value")

        if control == "brightness":
            self.write_json(set_brightness(value))
            return

        if control == "volume":
            self.write_json(set_volume(value))
            return

        self.send_error(400, "Contrôle inconnu")

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()

    def write_json(self, value):
        body = json.dumps(value).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, format, *args):
        if self.path.split("?", 1)[0] == "/surface-status":
            return
        super().log_message(format, *args)


def main():
    port = int(os.environ.get("GLASSDECK_SURFACE_WEB_PORT", "8090"))
    mimetypes.add_type("text/javascript", ".js")

    server = ThreadingHTTPServer(("", port), GlassDeckHandler)
    print(f"GlassDeck surface web listening on http://0.0.0.0:{port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
