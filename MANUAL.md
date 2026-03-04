# DaRipped Tiny Computer — Master Manual

**Version 2.0.x · Android ARM64 · Arch Linux ARM Edition**

---

## Table of Contents

1. [User Guide](#1-user-guide)
   - [What Is DaRipped Tiny Computer?](#11-what-is-daripped-tiny-computer)
   - [System Requirements](#12-system-requirements)
   - [First Launch Walkthrough](#13-first-launch-walkthrough)
   - [Using the Desktop](#14-using-the-desktop)
   - [Switching Display Backends](#15-switching-display-backends)
   - [Managing Containers](#16-managing-containers)
2. [Installation Guide](#2-installation-guide)
   - [Install from APK (End Users)](#21-install-from-apk-end-users)
   - [Permissions Explained](#22-permissions-explained)
   - [Uninstalling](#23-uninstalling)
3. [Customization Guide](#3-customization-guide)
   - [Display and Resolution Settings](#31-display-and-resolution-settings)
   - [VNC Password](#32-vnc-password)
   - [Custom Boot Commands](#33-custom-boot-commands)
   - [Installing Packages with Pacman](#34-installing-packages-with-pacman)
   - [Audio Setup](#35-audio-setup)
   - [Enabling Shizuku for Enhanced Performance](#36-enabling-shizuku-for-enhanced-performance)
   - [Using Termux:X11 Instead of noVNC](#37-using-termuxX11-instead-of-novnc)
4. [Reference Guide](#4-reference-guide)
   - [App Settings Reference](#41-app-settings-reference)
   - [Container JSON Schema](#42-container-json-schema)
   - [Key Paths Inside the Container](#43-key-paths-inside-the-container)
   - [Default Credentials](#44-default-credentials)
   - [Included Software](#45-included-software)
   - [Display Backend Comparison](#46-display-backend-comparison)
5. [Troubleshooting Guide](#5-troubleshooting-guide)
   - [Setup Hangs / Never Completes](#51-setup-hangs--never-completes)
   - [Black Screen After Setup](#52-black-screen-after-setup)
   - [VNC Connection Refused](#53-vnc-connection-refused)
   - [Very Slow Performance](#54-very-slow-performance)
   - [Cannot Install Packages (Pacman Errors)](#55-cannot-install-packages-pacman-errors)
   - [Audio Not Working](#56-audio-not-working)
   - [Termux:X11 / AVNC Not Connecting](#57-termux-x11--avnc-not-connecting)
   - [Resetting / Starting Fresh](#58-resetting--starting-fresh)
   - [Getting Logs for Bug Reports](#59-getting-logs-for-bug-reports)

---

## 1. User Guide

### 1.1 What Is DaRipped Tiny Computer?

DaRipped Tiny Computer runs a **full Arch Linux ARM desktop** inside an Android app — no root required, no PC needed. It uses `proot` (userspace containerization) to run a complete Linux environment on your phone or tablet.

What you get:
- **XFCE desktop** — a full graphical environment with file manager, terminal, and taskbar
- **Firefox** — pre-installed browser running natively inside Linux
- **Pacman** — Arch Linux's package manager to install thousands of additional Linux apps
- **VNC-based display** — the desktop appears inside the app or via a VNC client of your choice

This is a fork of [Cateners/tiny_computer](https://github.com/Cateners/tiny_computer) converted from Debian to Arch Linux ARM, and optimized for the Google Pixel 9.

---

### 1.2 System Requirements

| Requirement | Minimum |
|---|---|
| Android version | 10 (API 29) or higher |
| Architecture | ARM64 (aarch64) |
| Free storage | 3 GB |
| RAM | 4 GB recommended |
| Root | **Not required** |

> **Tested on:** Google Pixel 9. Other ARM64 Android devices should work but are not officially tested.

---

### 1.3 First Launch Walkthrough

1. **Open the app.** A loading screen with a progress bar appears.
2. **Wait for extraction.** The app unpacks ~1.1 GB of Arch Linux files into your device's private storage. This takes **5–15 minutes** depending on your device's storage speed. Do not close the app.
3. **Desktop appears.** Once setup is complete, the XFCE desktop loads in the built-in noVNC viewer automatically.
4. **Subsequent launches** are fast (seconds), since the rootfs is already extracted.

> ⚠️ **Do not close the app or lock the screen during first-launch setup** — some devices pause background processes when the screen is off.

---

### 1.4 Using the Desktop

The desktop runs inside the app's WebView (noVNC). Interaction works as follows:

| Action | How |
|---|---|
| Left click | Tap |
| Right click | Long-press |
| Scroll | Two-finger swipe |
| Type text | Tap a text field, then use your keyboard |
| Zoom in/out | Pinch gesture |
| Open terminal | Right-click desktop → "Open Terminal Here", or find the terminal in the taskbar |

**Default user:** `tiny`  
**Default password:** `tiny` (used for `sudo` commands)

---

### 1.5 Switching Display Backends

Three display backends are supported:

| Backend | App needed | Best for |
|---|---|---|
| **noVNC** (default) | None — built in | Easy, works out of the box |
| **AVNC** | [AVNC on F-Droid/Play](https://github.com/gujjwal00/avnc) | Better touch controls, hardware keyboard |
| **Termux:X11** | [Termux:X11](https://github.com/termux/termux-x11) | Lowest latency, native X11 |

To switch:
1. Open the app's **Settings** (gear icon or three-dot menu)
2. Find **Display Backend**
3. Select your preferred option
4. Restart the container

---

### 1.6 Managing Containers

The app supports multiple containers. Each container is an independent Linux installation with its own filesystem, settings, and VNC password.

- **Switch containers:** Use the container selector in the app's main screen
- **Add a container:** Settings → Containers → Add (requires a rootfs archive)
- **Default container:** The container opened on app launch; configurable in Settings

---

## 2. Installation Guide

### 2.1 Install from APK (End Users)

1. Go to the [**Releases page**](https://github.com/DaRipper91/DaRipped_tiny_computer/releases/latest)
2. Download `app-arm64-v8a-release.apk`
3. On your Android device, open **Settings → Security** (or **Settings → Apps → Special App Access → Install Unknown Apps**) and enable installation from your browser or file manager
4. Open the downloaded APK file and tap **Install**
5. Open **DaRipped Tiny Computer** from your app drawer
6. Allow any permissions the app requests (storage access)

> **Note:** The APK is ~1.1 GB because it bundles the entire Arch Linux rootfs. Make sure you have a stable connection when downloading.

---

### 2.2 Permissions Explained

| Permission | Why it's needed |
|---|---|
| **Storage (Read/Write)** | Extracting and running the Linux rootfs in app-private storage |
| **Internet** | VNC WebView and any network activity inside Linux |
| **Notifications** (optional) | Background service status during long-running operations |

The app does **not** request root, location, camera, microphone, or contacts.

---

### 2.3 Uninstalling

Uninstall via Android **Settings → Apps → DaRipped Tiny Computer → Uninstall**.

This removes the app AND all Linux data stored in the app's private directory (the extracted rootfs). You will need to re-extract on fresh install.

> To keep your data across reinstalls, back up `/data/user/0/com.fct.da_ripped_tiny_computer/` using a file manager with root access or ADB before uninstalling.

---

## 3. Customization Guide

### 3.1 Display and Resolution Settings

The default VNC resolution is tuned for the **Pixel 9 screen** (~1080×2400 at ~430 DPI). To change it:

1. Open **Settings** in the app
2. Find **VNC Resolution** and **DPI**
3. Enter your preferred values (e.g., `1920x1080` at `96` DPI for a TV/monitor-like feel)
4. Restart the container

Common resolutions:
| Screen type | Resolution | DPI |
|---|---|---|
| Phone (default) | 1080×2160 | 420 |
| Tablet | 1920×1200 | 160 |
| Landscape mode | 1920×1080 | 120 |

---

### 3.2 VNC Password

The default VNC password is set automatically during first-launch setup. To change it:

1. Open a terminal inside the Linux desktop
2. Run: `vncpasswd`
3. Enter your new password when prompted
4. Restart VNC: kill the current VNC server and relaunch from the app

Alternatively, change `vncPassword` in the container settings JSON (Settings → Containers → Edit).

---

### 3.3 Custom Boot Commands

You can add custom commands that run automatically when the container starts:

1. Go to **Settings → Containers → Edit**
2. Find the **Commands** list
3. Add entries with a `name` and a `command` field (shell commands run inside proot)

Example — auto-start a web server:
```json
{ "name": "Start nginx", "command": "sudo systemctl start nginx" }
```

---

### 3.4 Installing Packages with Pacman

Inside the Linux terminal, use standard Arch Linux package management:

```bash
# Update package list
sudo pacman -Sy

# Full system upgrade
sudo pacman -Syu

# Install a package (e.g., vim, git, python)
sudo pacman -S vim

# Search for a package
pacman -Ss <keyword>

# Remove a package
sudo pacman -R <packagename>
```

> **Tip:** The `proot` environment has internet access via Android's network stack. DNS and HTTP/HTTPS work normally.

---

### 3.5 Audio Setup

Audio is routed via a Unix socket bridge (`tiny_virtual_mic`). Basic audio playback works through PulseAudio.

If audio is not working:
1. Make sure PulseAudio is installed: `sudo pacman -S pulseaudio`
2. Start PulseAudio manually: `pulseaudio --start`
3. Set the `PULSE_SERVER` environment variable if needed: `export PULSE_SERVER=unix:/tmp/pulse-socket`

---

### 3.6 Enabling Shizuku for Enhanced Performance

[Shizuku](https://shizuku.rikka.app/) gives the app ADB-level shell access (`rish`), enabling:
- **Faster rootfs extraction** (parallel I/O at higher priority)
- **Better process scheduling** (prevents Android from throttling proot)

**Setup:**
1. Install [Shizuku from Play Store or F-Droid](https://shizuku.rikka.app/)
2. Start Shizuku via USB debugging or wireless debugging (one-time per boot)
3. Open DaRipped Tiny Computer — it auto-detects Shizuku and uses `rish` automatically

No manual configuration is needed. The app falls back gracefully if Shizuku is not running.

---

### 3.7 Using Termux:X11 Instead of noVNC

For the lowest latency display:

1. Install [Termux:X11 from GitHub releases](https://github.com/termux/termux-x11/releases)
2. In the app's **Settings → Display Backend**, select **Termux:X11**
3. Restart the container — the XFCE session will open in the Termux:X11 app instead of the built-in viewer

> Termux:X11 requires the companion Termux app to be installed alongside it.

---

## 4. Reference Guide

### 4.1 App Settings Reference

| Setting key | Type | Default | Description |
|---|---|---|---|
| `defaultContainer` | int | `0` | Index of the container opened on launch |
| `defaultAudioPort` | int | `4718` | PulseAudio socket port |
| `autoLaunchVnc` | bool | `true` | Automatically start VNC on container launch |
| `lastDate` | string | `1970-01-01` | Last launch date (internal) |
| `isTerminalWriteEnabled` | bool | `false` | Allow typing in the in-app terminal |
| `isTerminalCommandsEnabled` | bool | `false` | Enable quick-command buttons in terminal |
| `termMaxLines` | int | `4095` | Terminal scroll buffer size |
| `termFontScale` | double | `1.0` | Terminal font size multiplier |

Settings are stored via Android `SharedPreferences` and persist across app restarts.

---

### 4.2 Container JSON Schema

Each container is described by a JSON object stored in `SharedPreferences` under `containersInfo`:

```json
{
  "name": "Arch Linux",
  "boot": "proot-distro login archlinux --user tiny",
  "vnc": "startnovnc &",
  "vncPassword": "yourpassword",
  "vncUrl": "http://127.0.0.1:36081/vnc.html",
  "vncUri": "vnc://127.0.0.1:5901",
  "commands": [
    { "name": "Open Terminal", "command": "xterm &" }
  ]
}
```

| Field | Description |
|---|---|
| `name` | Display name shown in the container selector |
| `boot` | Shell command to start the container (runs in Android shell) |
| `vnc` | Command to start the VNC server (runs inside proot) |
| `vncPassword` | Password used to authenticate VNC connections |
| `vncUrl` | URL for the noVNC WebView |
| `vncUri` | VNC URI for external clients (AVNC) |
| `commands` | Array of quick-launch commands shown in the UI |

---

### 4.3 Key Paths Inside the Container

| Path | Purpose |
|---|---|
| `/home/tiny/` | Home directory for the default user |
| `/etc/pacman.conf` | Pacman configuration |
| `/etc/locale.gen` | Locale settings |
| `/root/.vnc/passwd` | VNC password file (hashed) |
| `/tmp/.X1-lock` | X11 display lock (VNC running indicator) |
| `/var/log/` | System logs |

**From Android's perspective**, the rootfs lives at:
```
/data/user/0/com.fct.da_ripped_tiny_computer/files/containers/0/
```
(accessible via ADB or root file managers)

---

### 4.4 Default Credentials

| Account | Username | Password |
|---|---|---|
| Linux user | `tiny` | `tiny` |
| Root (sudo) | — | `tiny` (sudo password) |
| VNC | — | Auto-generated on first launch |

> **Security note:** Change the default password after setup, especially if you plan to expose VNC to a network: `passwd tiny`

---

### 4.5 Included Software

Pre-installed in the Arch Linux ARM rootfs:

| Software | Purpose |
|---|---|
| XFCE 4 | Desktop environment |
| TigerVNC | VNC server |
| noVNC | Browser-based VNC client (served locally) |
| Firefox | Web browser |
| xterm | Terminal emulator |
| Pacman | Package manager |
| Base utilities | `bash`, `coreutils`, `grep`, `sed`, `awk`, `curl`, `wget`, `git` |

---

### 4.6 Display Backend Comparison

| Feature | noVNC | AVNC | Termux:X11 |
|---|---|---|---|
| Requires extra app | ❌ No | ✅ AVNC | ✅ Termux + X11 |
| Latency | Medium | Low | Very low |
| Touch controls | Basic | Good | Native |
| Hardware keyboard | Limited | Full | Full |
| Copy/paste | Via noVNC toolbar | Native | Native |
| Multi-monitor | ❌ | ❌ | ✅ |
| Clipboard sync | Manual | Auto | Auto |

---

## 5. Troubleshooting Guide

### 5.1 Setup Hangs / Never Completes

**Symptom:** Progress bar reaches 100% and freezes. App shows loading screen indefinitely.

**Cause (fixed in v2.0.1):** A bug where `G.currentContainer` (an internal index) was accessed before initialization during first-time setup. This caused a silent `LateInitializationError` that left the loading screen frozen.

**Fix:** Update to **v2.0.1 or later**. If you're on an older version:
1. Uninstall the app
2. Download the latest APK from [Releases](https://github.com/DaRipper91/DaRipped_tiny_computer/releases/latest)
3. Reinstall and relaunch

**If still hanging after v2.0.1:**
- Make sure you have at least **3 GB of free storage**
- Try rebooting your device and relaunching
- Check for error logs (see [§5.9](#59-getting-logs-for-bug-reports))

---

### 5.2 Black Screen After Setup

**Symptom:** Setup completes but the display shows a black screen or the app hangs on the loading screen.

**Fixed in v2.0.3 (Pixel 9 / Android 14):** A startup race where `Future.delayed(Duration.zero)` blocked the first Flutter frame, combined with missing `colorSchemeSeed` fallbacks in `DynamicColorBuilder`, caused a UI lockup on Pixel 9 and Android 14 devices. Update to **v2.0.3 or later** to resolve this.

**Other possible causes and fixes:**

| Cause | Fix |
|---|---|
| VNC server didn't start | Tap the restart/refresh button in the app toolbar |
| noVNC WebView not loaded | Pull down to refresh or close and reopen the app |
| XFCE session crashed | Open the in-app terminal and run `startxfce4 &` |
| Wrong VNC URL | Go to Settings → check VNC URL matches `http://127.0.0.1:36081/vnc.html` |

---

### 5.3 VNC Connection Refused

**Symptom:** "Connection refused" error in noVNC or AVNC.

**Steps:**
1. In the in-app terminal, check if VNC is running:
   ```bash
   ps aux | grep vnc
   ```
2. If not running, start it:
   ```bash
   startnovnc &
   ```
3. Check the VNC port is correct — default is `5901` (VNC) / `36081` (noVNC HTTP)
4. Make sure no firewall rule on Android is blocking localhost connections (rare but possible on some custom ROMs)

---

### 5.4 Very Slow Performance

**Symptom:** Desktop is laggy, apps take long to open.

**Tips to improve performance:**

1. **Enable Shizuku** (see [§3.6](#36-enabling-shizuku-for-enhanced-performance)) for better process scheduling
2. **Reduce VNC resolution** — lower resolution = less data to transmit (see [§3.1](#31-display-and-resolution-settings))
3. **Switch to Termux:X11** for lower display latency (see [§3.7](#37-using-termuxX11-instead-of-novnc))
4. **Close background apps** to free RAM for proot
5. **Use lightweight apps** inside Linux — prefer CLI tools or lightweight GTK apps over Electron/heavy GUI apps
6. **Avoid storing large files** in the Linux filesystem — write speed is limited by Android's storage

---

### 5.5 Cannot Install Packages (Pacman Errors)

**"failed to synchronize all databases"**
```bash
# Re-sync mirrors
sudo pacman -Syy
# If still failing, update mirror list
sudo pacman -S reflector
sudo reflector --country US --sort rate --save /etc/pacman.d/mirrorlist
```

**"error: failed to commit transaction (invalid or corrupted package)"**
```bash
sudo pacman -Sc   # clear cached packages
sudo pacman -Syu  # try upgrade again
```

**"signature from ... is unknown trust"**
```bash
sudo pacman-key --init
sudo pacman-key --populate archlinuxarm
```

---

### 5.6 Audio Not Working

1. Check PulseAudio is running: `pulseaudio --check -v`
2. Start it if not: `pulseaudio --start`
3. List audio sinks: `pactl list sinks short`
4. Set default sink if needed: `pactl set-default-sink <sink-name>`
5. Test playback: `paplay /usr/share/sounds/freedesktop/stereo/bell.oga`

If PulseAudio crashes repeatedly, reinstall it:
```bash
sudo pacman -S pulseaudio pulseaudio-alsa
```

---

### 5.7 Termux:X11 / AVNC Not Connecting

**Termux:X11:**
- Make sure the Termux:X11 companion app is installed AND the main Termux app is installed
- Confirm the display backend in app Settings is set to **Termux:X11**
- Relaunch the container after changing the backend setting

**AVNC:**
- Verify the VNC URI in the app Settings (e.g., `vnc://127.0.0.1:5901`)
- Try adding the connection manually in AVNC using `127.0.0.1` port `5901`
- Confirm the VNC server is running (see [§5.3](#53-vnc-connection-refused))

---

### 5.8 Resetting / Starting Fresh

If the container is corrupted or you want a clean slate:

**Option A — From inside the app:**
1. Go to **Settings → Containers**
2. Select the container and choose **Delete**
3. Restart the app — it will extract fresh on next launch

**Option B — Via ADB:**
```bash
adb shell
rm -rf /data/user/0/com.fct.da_ripped_tiny_computer/files/containers/
```
Then relaunch the app.

**Option C — Uninstall and reinstall** (also deletes all settings)

> ⚠️ Resetting deletes all files you've created inside Linux. Back up `/home/tiny/` first if needed.

---

### 5.9 Getting Logs for Bug Reports

If you need to report a bug, include:

1. **Android version and device model**
2. **App version** (visible in Settings → About)
3. **Android bug report:** On your device go to Developer Options → Take Bug Report (or `adb bugreport bugreport.zip`)
4. **App log file:** Located inside the container at `/tmp/tiny_computer.log` (if it exists)
5. **Steps to reproduce** the issue

Submit bug reports at: https://github.com/DaRipper91/DaRipped_tiny_computer/issues

---

*Manual version: 2.0.3 · Last updated: 2026-03-04*
