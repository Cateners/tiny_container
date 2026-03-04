# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DaRipped Tiny Computer is a Flutter Android app that runs a full Arch Linux ARM desktop (XFCE) on Android without root. It's a fork of [Cateners/tiny_computer](https://github.com/Caterers/tiny_computer), converted from Debian to Arch Linux ARM. The app bundles a compressed rootfs, extracts it on first launch, and runs it via proot with VNC-based display output.

**Target:** Android ARM64 (optimized for Pixel 9)
**License:** GPLv3
**Package name:** `da_ripped_tiny_computer` (Dart), `tiny_computer` (internal imports)

## Build Commands

### Build the Arch Linux ARM rootfs (requires Linux host with sudo + systemd-nspawn)
```bash
sudo ./extra/build-arch-rootfs.sh [--xfce|--lxqt] [--split-size SIZE]
```
Output goes to `extra/archroot-build/output/` as split chunks (xaa, xab, etc.). Copy these to `assets/`.

### Build the APK
```bash
flutter pub get
flutter build apk --target-platform android-arm64 --split-per-abi --release
```
Output: `build/app/outputs/flutter-apk/`

### Run analysis
```bash
flutter analyze
```

### Run tests
```bash
flutter test                              # all tests
flutter test test/validate_between_test.dart  # single test file
```

## Architecture

### Flutter App (`lib/`)
- **`main.dart`** — App entry point, UI, terminal emulation (xterm), permissions, WebView for noVNC. Contains the main widget tree and display mode selection (noVNC/AVNC/Termux:X11).
- **`workflow.dart`** — Container lifecycle: rootfs extraction, proot setup, VNC server management, Shizuku/rish integration. Contains `G` (global state: paths, PTYs, current container index, BuildContext), `Util` (static helpers for file ops, shell execution, validation), `D` (defaults), and `Workflow` (async lifecycle methods).
- **`settings.dart`** — `GlobalSettings` singleton wrapping SharedPreferences with typed property accessors and lazy default initialization.
- **`models.dart`** — `ContainerInfo` and `CommandInfo` data classes with JSON serialization for container configuration.
- **`l10n/`** — Localization (Chinese/English). Configured via `l10n.yaml` with `generate: true` in pubspec.

### Rootfs Build System (`extra/`)
- **`build-arch-rootfs.sh`** — Automated builder: downloads Arch Linux ARM tarball, configures via systemd-nspawn, installs XFCE/TigerVNC/Firefox/noVNC, creates user 'tiny', packages as `archlinux.tar.xz`, splits into 98MB chunks for APK asset limits.
- **`build-arch-rootfs.md`** — Manual step-by-step rootfs building guide.

### Native Bridge Components (`extra/`)
- **`getifaddrs_bridge/`** — C server/client pair enabling the proot container to query Android's network interfaces via Unix socket IPC.
- **`tiny_virtual_mic.c`** — PulseAudio audio bridge from Android to container via Unix socket.
- **`cross/`** — Hangover/Wine build scripts for x86 emulation support.

## Key Design Decisions

- **Rootfs split into 98MB chunks** to work around Android APK asset size limits. Chunks are reassembled at runtime.
- **proot (not chroot)** enables running without device root, compatible with SELinux-enforcing devices.
- **Three display backends:** in-app noVNC (WebView), AVNC (external VNC), Termux:X11 (native X11). All are optional; noVNC is the default.
- **Shizuku integration is optional** — provides ADB-level shell for faster extraction and higher process priority, but app works without it.
- **Custom git dependencies:** `x11_flutter` and `avnc_flutter` are pinned to specific commits from the `tiny-computer` GitHub org.

## Testing Notes

- Tests that use `Util` or localized strings need a `MaterialApp` with full localization delegates and a `Builder` that sets `G.homePageStateContext`. See `test/validate_between_test.dart` for the pattern.
- Import test files with `package:da_ripped_tiny_computer/` (the actual Dart package name), not `package:tiny_computer/`.

## Conventions

- Original upstream code has Chinese comments; new code uses English.
- The Dart package is named `da_ripped_tiny_computer`; all internal imports use `package:da_ripped_tiny_computer/`.
- `ShizukuHelper` accepts an injectable `processRunner` parameter (default `Process.run`) to support unit testing without spawning real processes.
- `waitForXServer` accepts a mockable `isReadyCheck` callback parameter for testability.
- The rootfs build script must run as root on an Arch/CachyOS host (or any Linux with qemu-user-static for cross-arch).
