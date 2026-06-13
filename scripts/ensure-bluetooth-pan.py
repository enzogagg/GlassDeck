#!/usr/bin/env python3
import re
import shutil
import subprocess
import sys
import time


NAME_HINTS = ("mac", "macbook", "imac", "apple", "glassdeck")
UUID_HINTS = ("personal area network", "network access point", "pan")


def run(args):
    return subprocess.run(
        args,
        check=False,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True,
        timeout=4,
    ).stdout


def bluetoothctl_available():
    return shutil.which("bluetoothctl") is not None


def paired_devices():
    output = run(["bluetoothctl", "devices", "Paired"])
    devices = []

    for line in output.splitlines():
        match = re.match(r"Device\s+([0-9A-F:]{17})\s+(.+)$", line.strip(), re.I)
        if match:
            devices.append((match.group(1), match.group(2)))

    return devices


def device_info(address):
    output = run(["bluetoothctl", "info", address])
    info = {"name": "", "uuids": [], "trusted": False, "connected": False}

    for line in output.splitlines():
        stripped = line.strip()
        lower = stripped.lower()
        if lower.startswith("name:"):
            info["name"] = stripped.split(":", 1)[1].strip()
        elif lower.startswith("trusted:"):
            info["trusted"] = "yes" in lower
        elif lower.startswith("connected:"):
            info["connected"] = "yes" in lower
        elif lower.startswith("uuid:"):
            info["uuids"].append(stripped.split(":", 1)[1].strip().lower())

    return info


def score_device(address, name):
    info = device_info(address)
    score = 0
    combined = f"{name} {info['name']}".lower()

    if any(hint in combined for hint in NAME_HINTS):
        score += 10

    if any(
        hint in uuid
        for uuid in info["uuids"]
        for hint in UUID_HINTS
    ):
        score += 50

    if info["connected"]:
        score += 20

    if info["trusted"]:
        score += 5

    return score, info


def connect_candidate(address):
    run(["bluetoothctl", "trust", address])
    run(["bluetoothctl", "connect", address])


def bnep_interfaces_present():
    try:
        output = run(["ip", "-o", "link", "show"])
    except FileNotFoundError:
        return False

    return any("bnep" in line.lower() or "pan" in line.lower() for line in output.splitlines())


def ensure_pan_connection():
    if not bluetoothctl_available():
        return 0

    devices = paired_devices()
    if not devices:
        return 0

    scored = []
    for address, name in devices:
        score, info = score_device(address, name)
        if score > 0:
            scored.append((score, address, name, info))

    scored.sort(reverse=True, key=lambda item: item[0])

    for _, address, _, info in scored:
        if info["connected"] and bnep_interfaces_present():
            return 0
        connect_candidate(address)
        time.sleep(1)
        if bnep_interfaces_present():
            return 0

    return 0


def main():
    try:
        return ensure_pan_connection()
    except Exception:
        return 0


if __name__ == "__main__":
    sys.exit(main())
