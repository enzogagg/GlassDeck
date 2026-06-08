# GlassDeck Services

This directory is intended for modular service packages that should run on the Surface.

## Package Format

A package is a directory that contains a `start.sh` executable.

```text
services/
└── my-service/
    └── start.sh
```

## Installation

To install a service and enable it on boot:

```bash
./scripts/install-service.sh ./services/my-service
```

## Management

Since services are installed as `systemd` user units, you can manage them using standard commands:

- **Status:** `systemctl --user status glassdeck-<name>`
- **Stop:** `systemctl --user stop glassdeck-<name>`
- **Restart:** `systemctl --user restart glassdeck-<name>`
- **Logs:** `journalctl --user -u glassdeck-<name> -f`

## Boot Persistence

To ensure services start at boot without requiring an interactive login, run:

```bash
loginctl enable-linger $USER
```
