# DaRipped Tiny Computer — Arch Linux Edition

[![Latest Release](https://img.shields.io/github/v/release/DaRipper91/DaRipped_tiny_computer?label=Download&style=for-the-badge)](https://github.com/DaRipper91/DaRipped_tiny_computer/releases/latest)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg?style=for-the-badge)](COPYING)
[![Platform](https://img.shields.io/badge/Platform-Android%20ARM64-green?style=for-the-badge)](https://github.com/DaRipper91/DaRipped_tiny_computer/releases/latest)
[![Manual](https://img.shields.io/badge/📖_Manual-read_now-blue?style=for-the-badge)](MANUAL.md)

**Full Arch Linux ARM desktop on Android — no root required. Highly optimized for Pixel 9 and Tensor G4.**

A specialized workstation for intelligence and knowledge generation. This is a fork of [Cateners/tiny_computer](https://github.com/Cateners/tiny_computer), fully migrated from Debian to Arch Linux ARM with modern Android 14 security bypasses.

---

## Installation

1. Go to the [**Latest Release**](https://github.com/DaRipper91/DaRipped_tiny_computer/releases/latest)
2. Download `app-arm64-v8a-release.apk`
3. Enable **"Install from unknown sources"** in Android Settings → Security
4. Install and open the app
5. Wait for the first-launch setup to complete (~5–15 minutes depending on storage speed)
6. The XFCE desktop will appear via the selected display backend

> **Requirements:** Android 10+, ARM64 device, ~4 GB free storage

---

## Features

- **Full Arch Linux ARM** — `pacman` package manager, AUR support, optimized for Cortex-X4 (Tensor G4).
- **Android 14+ Optimized** — Uses `PROOT_NO_SECCOMP=1` to bypass ptrace restrictions on modern kernels.
- **Hardware Acceleration** — VirGL/Mali-G715 passthrough for fluid graphical performance.
- **PipeWire Audio** — High-fidelity audio pipeline with advanced DSP support.
- **Neural Workflow Ready** — Built-in templates for knowledge ingestion and Obsidian-ready vaults.
- **One-tap setup** — Rootfs is bundled in the APK as high-performance GZIP chunks.
- **Display Backends**:
  - [**Termux:X11**](https://github.com/termux/termux-x11) — Native X11 passthrough (Recommended).
  - Built-in **noVNC** (WebView) — Works out of the box.
  - [**AVNC**](https://github.com/gujjwal00/avnc) — Native Android VNC client support.

---

## Architecture: The Bootstrap System

Because `systemd` is incompatible with `proot`, DaRipped uses a custom two-stage bootstrap:

1. **`start-arch.sh`**: Handles kernel-level initialization, manual D-Bus system bus generation, and dynamic DNS injection from the Android host.
2. **`start-desktop`**: Manages the XFCE session lifecycle, display socket synchronization, and HiDPI scaling logic.

---

## Changelog

### v2.1.0 (Current)
- **New Architecture:** Switched to a two-stage bootstrap system (`start-arch.sh` -> `start-desktop`) to bypass systemd crashes.
- **Kernel Fix:** Injected `PROOT_NO_SECCOMP=1` to ensure stability on Android 14+ (Pixel 9).
- **Performance:** Replaced XZ rootfs chunks with GZIP for faster extraction on high-speed UFS 4.0 storage.
- **Graphics:** Optimized VirGL environment variables for the Mali-G715 (Tensor G4) GPU.
- **Audio:** Migrated from PulseAudio to PipeWire for advanced userspace audio orchestration.
- **Workflow:** Added `to_vault` intelligence sink and high-speed Rust-based parsing toolkit (`ripgrep`, `fd`, `fzf`).

### v2.0.7
- **New:** Desktop environment selection dialog on first launch — choose XFCE4 or LXQt.
- **New:** Termux:X11 is now the default display backend for new installs.

### v2.0.0
- Initial release: Arch Linux ARM migration replacing upstream Debian rootfs.

---

## Building from Source

### 1. Clone
```bash
git clone https://github.com/DaRipper91/DaRipped_tiny_computer.git
cd DaRipped_tiny_computer
```

### 2. Build the APK
Ensure the Flutter SDK is in your path and target the `arm64-v8a` ABI:
```bash
flutter pub get
flutter build apk --release \
    --target-platform android-arm64 \
    --split-per-abi \
    --obfuscate \
    --split-debug-info=./debug_info
```

---

## Credits

- [**Cateners/tiny_computer**](https://github.com/Cateners/tiny_computer) — The original upstream project.
- [**Termux**](https://termux.dev/en/) — `proot`, `busybox`, and X11 tooling.
- [**Arch Linux ARM**](https://archlinuxarm.org/) — The rolling-release base.

---

## License

[GNU General Public License v3.0](COPYING)
