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
