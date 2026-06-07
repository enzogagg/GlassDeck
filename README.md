# GlassDeck

A highly extensible, premium Stream Deck alternative that transforms a Linux-Surface tablet into a programmable control dashboard. 

Built entirely in Rust, it uses a distributed workspace architecture to bridge a fluid, Wayland-native touch interface (powered by Slint) with a lightweight, asynchronous background daemon on the host machine. Driven by real-time WebSockets, its plugin-oriented design allows developers to easily map custom actions, trigger local scripts, and build interactive modules for any workflow—bringing the infinite customizability of smart home dashboards to your daily workstation.

## Workspace

This repository is a Rust workspace composed of:

- `shared`: shared protocol and data structures.
- `surface-client`: Linux-Surface touch client powered by Slint.
- `mac-daemon`: host-side daemon.

## Requirements

- Rust stable toolchain.
- `rustfmt` and `clippy` components.

The repository includes `rust-toolchain.toml`, so `rustup` will install the expected stable toolchain components automatically when needed.

## Development

```sh
cargo check --workspace --all-targets
cargo fmt --all
cargo clippy --workspace --all-targets -- -D warnings
cargo test --workspace --all-targets
```

The same commands are available as Cargo aliases:

```sh
cargo check-all
cargo fmt-all
cargo lint
cargo test-all
```

## Repository Hygiene

- `Cargo.lock` is committed because this workspace builds applications.
- Build outputs under `target/` are ignored.
- Local editor, OS, secret, and agent workspace files are ignored.

## Surface Installation

The Surface client can be installed for the current Linux user and started
automatically with a `systemd --user` service.

From a source checkout on the Surface:

```sh
./scripts/install-surface.sh
```

This command builds `surface-client` in release mode, installs it under
`~/.local/opt/glassdeck`, creates the `~/.local/bin/glassdeck-surface` command,
and enables `glassdeck-surface.service` for automatic startup.

If the Surface must start GlassDeck before a manual login, install with:

```sh
./scripts/install-surface.sh --enable-linger
```

The Linux KMS backend may require the Surface user to have device access through
groups such as `video`, `input`, or `render`, depending on the distribution.

Runtime features use standard Linux interfaces:

- Battery: `/sys/class/power_supply`.
- Network status: `nmcli` from NetworkManager.
- IP address: `ip` from iproute2.
- Manual brightness: `/sys/class/backlight`, with `brightnessctl` as fallback.
- Automatic brightness: Linux IIO ambient light sensor under `/sys/bus/iio/devices`.

Useful service commands:

```sh
systemctl --user status glassdeck-surface.service
systemctl --user restart glassdeck-surface.service
journalctl --user -u glassdeck-surface.service -f
```

To uninstall:

```sh
./scripts/uninstall-surface.sh
```

### Build a Downloadable Surface Package

On a Linux machine matching the Surface architecture:

```sh
./scripts/package-surface.sh
```

The package is written to `dist/glassdeck-surface-<version>-<arch>.tar.gz`.
Copy or download that archive on the Surface, extract it, then run:

```sh
tar -xzf glassdeck-surface-<version>-<arch>.tar.gz
cd glassdeck-surface-<version>-<arch>
./install.sh
```

For boot startup before login:

```sh
./install.sh --enable-linger
```
