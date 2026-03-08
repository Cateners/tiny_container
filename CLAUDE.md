# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DaRipped Tiny Computer is a high-performance Arch Linux ARM workstation running on Android via PRoot. It is strictly optimized for **intelligence and knowledge generation**, specifically targeting the **Tensor G4 (Pixel 9)** architecture.

**Target:** Android ARM64 (API 34+ optimized)
**License:** GPLv3
**Package name:** `da_ripped_tiny_computer`

## Core Architecture: The Dual-Stage Bootstrap

Because `systemd` is incompatible with PRoot, initialization is handled by two specialized scripts:
1.  **`start-arch.sh`**: Handles kernel-level initialization, manual D-Bus system bus generation (`dbus-daemon --system`), and dynamic DNS injection.
2.  **`start-desktop`**: Synchronizes with the display socket (`X4`) and handles HiDPI scaling logic before launching XFCE4 via `dbus-launch`.

## Build Commands

### Build the APK
Ensure the Flutter SDK is ≥ 3.41 and target the `arm64-v8a` ABI:
```bash
flutter pub get
flutter build apk --release \
    --target-platform android-arm64 \
    --split-per-abi \
    --obfuscate \
    --split-debug-info=./debug_info
```
Output: `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`

## Key Optimization Decisions

- **Seccomp Bypass:** Uses `PROOT_NO_SECCOMP=1` to prevent Android 14 kernel ptrace denials.
- **Extraction Performance:** Uses GZIP (`tar -zxf`) for rootfs reassembly, optimized for UFS 4.0 storage speed.
- **Hardware Acceleration:** Routes OpenGL through the Mali-G715 via `GALLIUM_DRIVER=virpipe` and `MESA_EXTENSION_OVERRIDE="-GL_MESA_framebuffer_flip_y"`.
- **High-Fidelity Audio:** Implements PipeWire with JamesDSP bridge support for acoustic calibration.
- **Neural Workflow:** Includes a pre-configured `to_vault` intelligence sink for Obsidian-ready knowledge ingestion.

## Conventions

- All internal imports use `package:da_ripped_tiny_computer/`.
- New documentation and comments must be in English.
- The `Workflow.boot` static string is the source of truth for the PRoot execution path.
- `assets/patch.tar.gz` is the primary delivery mechanism for container-side scripts (`/usr/local/bin/`).
