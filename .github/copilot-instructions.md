# Copilot Instructions — DaRipped Tiny Computer

Flutter Android app that runs a full Arch Linux ARM (XFCE) desktop on Android without root, via proot + VNC. Fork of [Cateners/tiny_computer](https://github.com/Cateners/tiny_computer), converted from Debian to Arch Linux ARM.

**Target:** Android ARM64 (optimized for Pixel 9) · **minSdk:** 28 (Android 9) · **targetSdk:** 34 · **License:** GPLv3

---

## Commands

```bash
# Install dependencies
flutter pub get

# Build APK (ARM64 only)
flutter build apk --target-platform android-arm64 --split-per-abi --release
# With obfuscation (matches build.ps1 release workflow):
flutter build apk --target-platform android-arm64 --split-per-abi --release --obfuscate --split-debug-info=tiny_computer/sdi
# Output: build/app/outputs/flutter-apk/

# Release signing: create android/keystore.properties based on android/keystore.properties.example
# (storeFile, storePassword, keyAlias, keyPassword). Without it, release signing will fail.

# Lint / static analysis
flutter analyze

# Run all tests
flutter test

# Run a single test file
flutter test test/validate_between_test.dart

# Build the Arch Linux ARM rootfs (Linux host required, needs sudo + systemd-nspawn)
sudo ./extra/build-arch-rootfs.sh [--xfce|--lxqt] [--split-size SIZE]
# Output chunks go to extra/archroot-build/output/ → copy to assets/

# Package rootfs and build APK on Windows (PowerShell):
# .\build.ps1 xfce [lxqt] [-NameSuffix <suffix>]
# Splits a pre-built tar.xz from C:\Users\29513\Downloads\ into 98MB xa* chunks,
# copies them to assets/, then runs flutter build.
```

---

## Architecture

### Flutter App (`lib/`)

Only four Dart source files drive the entire app:

- **`main.dart`** — App entry point, full widget tree, terminal emulation (`xterm`), display mode selection (noVNC WebView / AVNC / Termux:X11), permissions.
- **`workflow.dart`** — Everything else: container lifecycle, rootfs extraction, proot setup, VNC management, Shizuku/rish integration, and all shared state. Contains key classes:
  - `G` — Static global state: `dataPath`, `prefs` (SharedPreferences), `settings` (GlobalSettings singleton), `termPtys`, `currentContainer`, `homePageStateContext`, display state flags.
  - `Util` — Static helpers: file/asset ops, shell execution via PTY, `validateBetween` (form validator). `Util.getGlobal(key)` delegates to `G.settings.getGlobal(key)`.
  - `D` — Default values: default boot command, shortcut command lists (Chinese & English variants), default VNC/virgl/HiDPI options.
  - `Workflow` — Static async methods for first-time setup, bootstrap install, rootfs extraction, VNC start/stop.
  - `ShizukuHelper` — Shizuku/rish integration with injectable `processRunner` for testability. `run(String executable, List<String> arguments)` either execs directly (no Shizuku) or POSIX-single-quote-escapes arguments into a `rish -c` string to prevent command injection.
- **`settings.dart`** — `GlobalSettings` singleton: typed property getters for every SharedPreferences key with automatic default-on-first-read. Never access `G.prefs` directly for known keys — use `Util.getGlobal(key)` or `G.settings.<property>`.
- **`models.dart`** — `ContainerInfo` and `CommandInfo` data classes for container JSON serialization. `ContainerInfo` preserves unknown JSON fields in `additionalProps` for forward compatibility.
- **`l10n/`** — Flutter gen-l10n localization (English + Simplified/Traditional Chinese). Template: `lib/l10n/intl_en.arb`.

### Rootfs / Asset Pipeline

- The Arch Linux ARM rootfs is **not** stored in git. Build it with `extra/build-arch-rootfs.sh`, then copy the split chunks (`xaa`, `xab`, …) to `assets/`. The script must run as root on an Arch/CachyOS host (or any Linux with `qemu-user-static` installed for cross-arch support).
- Chunks are capped at **98 MB** to work around Android APK asset size limits. They are reassembled at runtime before extraction.
- `assets/assets.zip` — bootstrap binaries (proot, busybox, tar, pulseaudio, virgl, etc.), symlinked into `$DATA_DIR/bin` and `$DATA_DIR/lib` on first launch.
- `assets/patch.tar.gz` — overlay files mounted into the container at `~/.local/share/tiny`.

### Native Bridge Components (`extra/`)

- **`getifaddrs_bridge/`** — C Unix-socket IPC pair letting the proot container query Android's network interfaces.
- **`tiny_virtual_mic.c`** — PulseAudio bridge from Android to container audio.
- **`cross/`** — Hangover/Wine build scripts for x86 emulation.

---

## Key Conventions

### Settings / Preferences

All persistent settings flow through the `GlobalSettings` singleton (`G.settings`). `Util.getGlobal(key)` is the single access point — it delegates to `G.settings.getGlobal(key)`, which reads the key if it exists or writes and returns the default on first call. Do not call `G.prefs` directly for known keys; always go through `Util.getGlobal` or `G.settings.<property>`.

Container-specific config (name, boot command, VNC URL, shortcut commands, bind mounts) is stored as a JSON string in the `containersInfo` string-list preference. Access it via `Util.getCurrentProp(key)` / `Util.setCurrentProp(key, value)` / `Util.addCurrentProp(key, value)`.

### Package Naming

The Dart package name is `da_ripped_tiny_computer`. Always import with `package:da_ripped_tiny_computer/`. Some upstream comments and legacy references still say `tiny_computer` — leave them as-is, do not rename.

### Localization

- Generated via `flutter gen-l10n` (`generate: true` in `pubspec.yaml`). Never edit generated files in `lib/l10n/app_localizations*.dart`.
- Add new strings to **all three** ARB files: `lib/l10n/intl_en.arb`, `lib/l10n/intl_zh.arb` (Simplified Chinese), and `lib/l10n/intl_zh_Hant.arb` (Traditional Chinese).
- ARB entries have no `@key` placeholder metadata blocks — parameterized strings use positional args without metadata.

### Testing

Tests that use `Util` methods touching localized strings (e.g., `validateBetween`) must:
1. Wrap with a full `MaterialApp` including all four localization delegates.
2. Use a `Builder` child that sets `G.homePageStateContext = context` before assertions.

See `test/validate_between_test.dart` for the canonical pattern.

For dependency injection in tests:
- `ShizukuHelper.processRunner` is a static field — assign a mock function in `setUp()` and reset to `Process.run` after each test.
- `Util.waitForXServer` accepts an optional `isReadyCheck` callback (`Future<bool> Function(String host, int port)`).
- `Util.isXServerReady` accepts an optional `connectSocket` function to avoid real network calls.

### Comments

Original upstream code uses Chinese comments. New code uses English comments. When modifying upstream code, you may leave existing Chinese comments in place.

### Display Backends

Three backends exist and are mutually exclusive at runtime: **noVNC** (default, in-app WebView), **AVNC** (external app), **Termux:X11** (native X11). The active backend is tracked via `G.wasAvncEnabled` / `G.wasX11Enabled`. When the noVNC WebView is active, Termux:X11-specific features (e.g., share link) are disabled.

### Custom Git Dependencies

`x11_flutter` and `avnc_flutter` are pinned to specific commits from the `tiny-computer` GitHub org (see `pubspec.yaml`). Do not bump these without testing display functionality end-to-end.
