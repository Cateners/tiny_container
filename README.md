# DaRipped Tiny Computer — Arch Linux Edition

[![Latest Release](https://img.shields.io/github/v/release/DaRipper91/DaRipped_tiny_computer?label=Download&style=for-the-badge)](https://github.com/DaRipper91/DaRipped_tiny_computer/releases/latest)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge)](COPYING)
[![Platform](https://img.shields.io/badge/Platform-Android%20ARM64-green?style=for-the-badge)](https://github.com/DaRipper91/DaRipped_tiny_computer/releases/latest)
[![Manual](https://img.shields.io/badge/📖_Manual-read_now-blue?style=for-the-badge)](MANUAL.md)

**Full Arch Linux ARM desktop on Android — no root required. Optimized for Pixel 9.**

A fork of [Cateners/tiny_computer](https://github.com/Cateners/tiny_computer) converted from Debian to Arch Linux ARM. Bundles a complete XFCE desktop environment that launches directly from a single APK install.

---

## Installation

1. Go to the [**Latest Release**](https://github.com/DaRipper91/DaRipped_tiny_computer/releases/latest)
2. Download `app-arm64-v8a-release.apk`
3. Enable **"Install from unknown sources"** in Android Settings → Security
4. Install and open the app
5. Wait for the first-launch setup to complete (~5–15 minutes depending on storage speed)
6. The XFCE desktop will appear in the built-in noVNC viewer

> **Requirements:** Android 10+, ARM64 device, ~3 GB free storage

---

## Features

- **Full Arch Linux ARM** — `pacman` package manager, AUR-compatible, rolling-release packages
- **No root required** — runs entirely via `proot` userspace containerization
- **One-tap setup** — rootfs is bundled in the APK; first launch extracts and configures everything automatically
- **Three display backends:**
  - Built-in **noVNC** (WebView) — works out of the box, no extra apps needed
  - [**AVNC**](https://github.com/gujjwal00/avnc) — richer VNC client experience
  - [**Termux:X11**](https://github.com/termux/termux-x11) — native X11 passthrough for lowest latency
- **XFCE desktop** with Firefox pre-installed
- **Pixel 9 optimized** — display resolution and DPI tuned for the Pixel 9 screen
- **Optional Shizuku/rish integration** — if [Shizuku](https://shizuku.rikka.app/) is installed, the app uses `rish` for ADB-level shell access: faster extraction, higher process priority

---

## How It Works

The APK bundles the Arch Linux ARM rootfs as split compressed assets (~1.1 GB). On first launch:

1. Bootstraps necessary binaries (`proot`, `busybox`, `tar`) into the app's private data directory
2. Reassembles and extracts the Arch Linux rootfs
3. Launches a `proot` container (no kernel modifications needed)
4. Starts TigerVNC server and serves the XFCE session
5. Opens the desktop via the selected display backend (noVNC by default)

On subsequent launches the container starts in seconds.

---

## Pixel 9 & Shizuku Setup

**Pixel 9:** The default VNC resolution and DPI are pre-configured for the Pixel 9's display. No manual tuning needed.

**Shizuku:** Completely optional. If detected, the app uses Shizuku's `rish` for privileged operations — faster rootfs extraction and improved scheduling. The app works identically without it.

---

## Changelog

### v2.0.2
- **New:** `GlobalSettings` and `ContainerInfo` classes replace raw SharedPreferences string parsing
- **New:** `ShizukuHelper` refactored for testability with injectable `processRunner`
- **New:** `waitForXServer` accepts a mockable `isReadyCheck` parameter
- **Tests:** Added unit tests for `isXServerReady`, `createDirFromString`, `waitForXServer`, `ShizukuHelper`, and extended `validateBetween` edge cases
- **Code health:** Chinese doc comments translated to English; dead code removed
- 📖 [Full documentation in MANUAL.md](MANUAL.md)

### v2.0.1
- **Fix:** Resolved first-launch hang at end of installation progress bar
  - `LateInitializationError` on `G.currentContainer` caused a silent crash before the container ever started
  - Added proper error handling in the workflow initializer to prevent the loading screen from freezing permanently

### v2.0.0
- Initial release: Arch Linux ARM replacing upstream Debian rootfs
- XFCE + TigerVNC + Firefox + noVNC bundled
- Shizuku/rish optional integration
- Termux:X11 and AVNC display backend support

---

## Building from Source

### Prerequisites

- Linux host (Arch/CachyOS recommended) with `sudo`, `systemd-nspawn`, `qemu-user-static`
- Flutter SDK ≥ 3.41
- Android SDK with API 34+ and build-tools

### 1. Clone

```bash
git clone https://github.com/DaRipper91/DaRipped_tiny_computer.git
cd DaRipped_tiny_computer
```

### 2. Build the rootfs

```bash
sudo ./extra/build-arch-rootfs.sh [--xfce|--lxqt] [--split-size SIZE]
```

Output goes to `extra/archroot-build/output/` as split chunks (`xaa`, `xab`, …). Copy them to `assets/`.

### 3. Build the APK

```bash
flutter pub get
flutter build apk --target-platform android-arm64 --split-per-abi --release
```

Output: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

---

## Credits

- [**Cateners/tiny_computer**](https://github.com/Cateners/tiny_computer) — the upstream project this is forked from
- [**Termux**](https://termux.dev/en/) — `proot`, `busybox`, and bootstrap tooling
- [**Arch Linux ARM**](https://archlinuxarm.org/) — the base rootfs for aarch64
- [**TigerVNC**](https://tigervnc.org/) / [**noVNC**](https://novnc.com/) — VNC server and in-app browser client

---

## License

[GNU General Public License v3.0](COPYING)
