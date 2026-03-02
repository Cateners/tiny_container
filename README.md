# DaRipped Tiny Computer — Arch Linux Edition

**One-click Arch Linux desktop on Android, optimized for Pixel 9.**

This project is a modification of the upstream [Cateners/tiny_computer](https://github.com/Cateners/tiny_computer), converting it from a Debian-based proot container to a streamlined Arch Linux ARM environment. It provides a full-featured Linux desktop (XFCE) that runs directly on Android devices without requiring root.

## Features

-   **Full Arch Linux ARM Environment:** A complete Arch Linux desktop experience, with `pacman` for package management.
-   **One-Click Setup:** Simply install the APK, open the app, and the Arch Linux environment is automatically extracted and configured.
-   **High Performance:** Runs on a `proot` container, offering near-native performance for CLI and GUI applications.
-   **Multiple Display Options:**
    -   In-app noVNC (via WebView) for convenience.
    -   [AVNC](https://github.com/gujjwal00/avnc) for a richer, more feature-full VNC experience.
    -   [Termux:X11](https://github.com/termux/termux-x11) for a native X11 server experience.
-   **Pixel 9 Optimized:** Includes defaults and configurations tailored for the Google Pixel 9's display and hardware.
-   **Shizuku/rish Integration (Optional):** For users with Shizuku, the app can leverage `rish` to gain ADB-level shell access for enhanced performance, such as faster rootfs extraction and higher process priority.

## How It Works

The application bundles a complete Arch Linux ARM rootfs as a compressed asset. On first launch, the app:
1.  Sets up a bootstrap environment with necessary binaries (`proot`, `busybox`, `tar`).
2.  Extracts the Arch Linux ARM rootfs into the app's private data directory.
3.  Launches a `proot` container, effectively running a Linux environment chrooted into the new rootfs.
4.  Starts a VNC server and provides multiple clients for accessing the XFCE desktop environment.

## Pixel 9 & Shizuku Setup

-   **Display:** The app defaults to a VNC resolution and DPI suitable for the Pixel 9's screen.
-   **Shizuku:** If you have the [Shizuku app](https://shizuku.rikka.app/) installed and running, this application will automatically detect it. It will use Shizuku's `rish` shell to perform certain operations with elevated privileges, leading to a smoother and faster experience. This is completely optional, and the app will function normally without it.

## Building from Source

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/DaRipper91/DaRipped_tiny_computer.git
    cd DaRipped_tiny_computer
    ```

2.  **Build the Rootfs:** The Arch Linux ARM rootfs is not included in the repository. You must build it yourself using the provided script. This requires a Linux machine with `sudo` and `systemd-nspawn`.
    ```bash
    sudo ./extra/build-arch-rootfs.sh
    ```

3.  **Copy Assets:** The build script will create a series of `x*` files (e.g., `xaa`, `xab`) in the `extra/archroot-build/output` directory. Copy all of these files into the `assets/` directory of the Flutter project. You will need to remove the existing `assets.zip` placeholder first.

4.  **Build the APK:**
    ```bash
    flutter build apk --target-platform android-arm64 --split-per-abi --release
    ```
    The resulting APK will be in `build/app/outputs/flutter-apk/`.

## Credits

-   **Upstream:** This project would not be possible without the excellent work done by Caten Hu on the original [tiny_computer](https://github.com/Cateners/tiny_computer).
-   **Proot & Termux:** The core container technology is powered by `proot` and other tools from the [Termux](https://termux.dev/en/) ecosystem.
-   **Arch Linux ARM:** For providing the base rootfs for aarch64 devices.
