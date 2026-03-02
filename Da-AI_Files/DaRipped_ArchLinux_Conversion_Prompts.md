# DaRipped_tiny_computer → Arch Linux Conversion Prompts

> **Target Repository:** `https://github.com/DaRipper91/DaRipped_tiny_computer`
> **Upstream Fork:** `https://github.com/Cateners/tiny_computer`
> **Goal:** Convert from Debian Trixie proot container to Arch Linux ARM proot container, optimized for Google Pixel 9 (non-root, Shizuku + rish)
> **Date Generated:** 2026-03-01

---

## Table of Contents

1. [Project Context & Architecture Overview](#1-project-context--architecture-overview)
2. [Prompt 1: Jules (Google Coding Bot)](#2-prompt-1-jules-google-coding-bot)
3. [Prompt 2: gemini-cli (Desktop — CachyOS)](#3-prompt-2-gemini-cli-desktop--cachyos)
4. [Prompt 3: gemini-cli-termux (Mobile — Pixel 9)](#4-prompt-3-gemini-cli-termux-mobile--pixel-9)
5. [Prompt 4: claude-cli (Claude Code)](#5-prompt-4-claude-cli-claude-code)
6. [Shared Reference: File-by-File Modification Map](#6-shared-reference-file-by-file-modification-map)
7. [Shared Reference: Arch Linux ARM rootfs Build Script](#7-shared-reference-arch-linux-arm-rootfs-build-script)
8. [Shared Reference: Shizuku/rish Integration Points](#8-shared-reference-shizukurish-integration-points)

---

## 1. Project Context & Architecture Overview

### What tiny_computer Is

`tiny_computer` is a Flutter Android application that bundles a complete Linux proot container (currently Debian Trixie/13) with a desktop environment (XFCE or LXQt). The app provides a one-click setup experience: install the APK, open it, and you have a full Linux desktop running on Android via proot—no Termux installation required. Graphics are rendered through noVNC (in-app WebView), AVNC, or Termux:X11.

### Architecture Breakdown

```
┌─────────────────────────────────────────────────────┐
│  Flutter Android App (Dart + Kotlin/Java)            │
│  ├── lib/main.dart         → UI layout               │
│  ├── lib/workflow.dart     → Core logic               │
│  │   ├── Util              → Utility class            │
│  │   ├── TermPty           → Terminal emulator        │
│  │   ├── G                 → Global variables         │
│  │   └── Workflow          → Boot sequence steps      │
│  └── lib/l10n/             → Localization files        │
├─────────────────────────────────────────────────────┤
│  Android Native Layer                                │
│  ├── android/app/src/main/jniLibs/arm64-v8a/         │
│  │   ├── proot (statically compiled)                  │
│  │   ├── busybox                                      │
│  │   ├── getifaddrs_bridge_server                     │
│  │   └── other native binaries                        │
│  └── android/ (Gradle build, manifest, etc.)          │
├─────────────────────────────────────────────────────┤
│  Assets (bundled in APK, split into ~98MB chunks)     │
│  ├── assets/xaa, xab, xac...  → split rootfs tarball  │
│  └── assets/patch.tar.gz      → post-extraction patches│
├─────────────────────────────────────────────────────┤
│  Runtime Container (extracted to app data dir)        │
│  ├── Debian Trixie arm64 rootfs  ← REPLACE WITH ARCH  │
│  ├── XFCE or LXQt desktop environment                 │
│  ├── VNC server (TigerVNC)                             │
│  ├── noVNC web client (patched)                        │
│  └── User: tiny / Password: tiny                       │
└─────────────────────────────────────────────────────┘
```

### What Must Change for Arch Linux

| Layer | Current (Debian) | Target (Arch Linux ARM) |
|---|---|---|
| **rootfs** | Debian Trixie arm64 via tmoe | Arch Linux ARM aarch64 via `archlinuxarm-*` tarball |
| **Package manager** | apt/dpkg | pacman |
| **Desktop environment** | XFCE/LXQt via apt | XFCE/LXQt via pacman |
| **Init scripts** | Debian-style `/etc/X11/xinit/Xsession` | Custom `.xinitrc` or arch-native X session |
| **VNC** | TigerVNC via tmoe | TigerVNC via pacman |
| **noVNC** | Patched noVNC from tmoe paths | noVNC installed to Arch-appropriate paths |
| **Locale** | tmoe locale management, `LANG=zh_CN.UTF-8` | `locale-gen` + `locale.conf`, default `en_US.UTF-8` |
| **User setup** | tmoe creates `tiny` user | Manual `useradd` with sudoers config |
| **Shell scripts in workflow.dart** | apt commands, Debian paths | pacman commands, Arch paths |
| **patch.tar.gz** | Debian-specific patches | Arch-specific patches (different lib paths) |
| **Pixel 9 optimization** | Generic arm64 | Tensor G4 awareness, Shizuku/rish integration |

### Key Paths That Differ

| Purpose | Debian Path | Arch Linux Path |
|---|---|---|
| Libraries | `/usr/lib/aarch64-linux-gnu/` | `/usr/lib/` |
| X session file | `/etc/X11/xinit/Xsession` | `/etc/X11/xinit/xinitrc` or custom |
| Package cache | `/var/cache/apt/` | `/var/cache/pacman/pkg/` |
| Sources config | `/etc/apt/sources.list` | `/etc/pacman.d/mirrorlist` + `/etc/pacman.conf` |
| tmoe paths | `/usr/local/etc/tmoe-linux/` | N/A (tmoe not used) |

---

## 2. Prompt 1: Jules (Google Coding Bot)

Jules operates as a GitHub-integrated autonomous coding agent. It can clone repos, create branches, make commits, and open pull requests. The following prompt is designed to be submitted as a task to Jules.

### How to Use

1. Go to Jules at `https://jules.google.com` (or via the GitHub integration)
2. Connect your fork: `DaRipper91/DaRipped_tiny_computer`
3. Paste the entire prompt below as a new task
4. Jules will create a branch, make changes, and open a PR

### The Prompt

```
TASK: Convert DaRipped_tiny_computer from Debian to Arch Linux ARM

REPOSITORY: https://github.com/DaRipper91/DaRipped_tiny_computer
UPSTREAM: https://github.com/Cateners/tiny_computer
BRANCH TO CREATE: feature/arch-linux-conversion

## CONTEXT

This Flutter Android app runs a Debian Trixie proot container with XFCE/LXQt
desktop on Android. I need you to convert ALL Debian-specific code, scripts,
and configurations to target Arch Linux ARM instead. The app will run on a
Google Pixel 9 (non-root, using Shizuku + rish for elevated operations).

The app architecture:
- Flutter app (Dart) in lib/ handles UI and boot workflow
- Native binaries in android/app/src/main/jniLibs/arm64-v8a/ (proot, busybox, etc.)
- Rootfs tarball split into chunks in assets/
- Shell commands executed from Dart via TermPty class in workflow.dart
- Graphics via noVNC (WebView), AVNC, or Termux:X11

## PHASE 1: DART SOURCE MODIFICATIONS (lib/)

### 1.1 workflow.dart — Core Logic Conversion

This is the most critical file. It contains the Workflow class that handles
everything from app launch to container startup. You must:

A) Find ALL instances of apt/dpkg commands and convert to pacman equivalents:
   - `apt update` → `pacman -Sy`
   - `apt upgrade` → `pacman -Syu`
   - `apt install <pkg>` → `pacman -S --noconfirm <pkg>`
   - `apt remove <pkg>` → `pacman -Rns --noconfirm <pkg>`
   - `apt clean` → `pacman -Scc --noconfirm`
   - `apt autoremove` → `pacman -Qdtq | pacman -Rns --noconfirm -` (orphan cleanup)
   - `dpkg -i <deb>` → There is no direct equivalent; use `pacman -U <pkg.tar.zst>`
   - `dpkg --configure -a` → Remove entirely (not applicable to pacman)

B) Find ALL Debian-specific file paths and update for Arch Linux:
   - `/usr/lib/aarch64-linux-gnu/` → `/usr/lib/`
   - `/etc/apt/sources.list` → `/etc/pacman.conf` and `/etc/pacman.d/mirrorlist`
   - `/usr/local/etc/tmoe-linux/` → Remove all tmoe references
   - `/etc/X11/xinit/Xsession` → `/etc/X11/xinit/xinitrc`

C) Update the rootfs extraction logic:
   - The current code reassembles split chunks (xaa, xab, etc.) into a
     debian.tar.xz and extracts it
   - Change the expected tarball name references from "debian" to "archlinux"
   - The extraction command itself (tar -xf) stays the same
   - Update any post-extraction validation that checks for Debian-specific files

D) Update container startup commands:
   - The proot launch command in workflow.dart sets up bind mounts and environment
   - Change LANG default from `zh_CN.UTF-8` to `en_US.UTF-8`
   - Update any references to /etc/debian_version or lsb_release
   - The proot binary itself does NOT change (it's distro-agnostic)

E) Update the "one-click install" hint commands:
   - The app shows users quick-install commands for common software
   - Convert all `apt install` hints to `pacman -S` equivalents
   - Update package names where they differ between Debian and Arch:
     * firefox-esr → firefox
     * build-essential → base-devel
     * python3 → python
     * python3-pip → python-pip
     * libgtk-3-dev → gtk3
     * vim-gtk3 → gvim

F) Add Shizuku/rish integration hooks:
   - Add a method `checkShizukuAvailable()` that checks for Shizuku's binder:
     `test -e /data/local/tmp/.shizuku/binder` or uses `rish` command availability
   - Add a method `executeViaRish(String command)` that wraps commands in:
     `rish -c "<command>"` for elevated operations
   - Use rish for operations that benefit from shell (ADB-level) permissions:
     * Accessing /data/local/tmp/ for faster rootfs extraction
     * Setting higher process priorities for the proot container
     * Accessing USB OTG devices if connected
   - Add a toggle in settings: "Use Shizuku for enhanced performance"
   - If Shizuku is not available, fall back to normal unprivileged operation

### 1.2 main.dart — UI Updates

A) Update all user-facing strings:
   - "Debian" → "Arch Linux"
   - "debian" → "archlinux" (in technical displays)
   - Update version description strings

B) Update the settings/control panel:
   - Add a new toggle: "Use Shizuku (requires Shizuku app)"
   - Add a new info display: "Container: Arch Linux ARM"
   - Add Pixel 9 display optimization settings:
     * Default VNC resolution suggestion: 2424x1080 (Pixel 9 native)
     * DPI suggestion: 420 (Pixel 9 native density)

C) Update locale handling:
   - Remove tmoe locale management references
   - Add direct locale-gen support:
     The locale change command should be:
     `sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen && locale-gen`

### 1.3 l10n/ — Localization Files

A) Update all localization strings that reference "Debian" to "Arch Linux"
B) Update all command examples shown to users
C) Add English as the primary/default locale (currently Chinese-first)

## PHASE 2: BUILD CONFIGURATION

### 2.1 pubspec.yaml

A) Update the app name/description:
   - name: da_ripped_tiny_computer (or appropriate)
   - description: "Click-to-run Arch Linux with desktop environment on Android"

B) Update version to indicate the Arch Linux conversion (e.g., 2.0.0)

### 2.2 android/ Build Files

A) In android/app/build.gradle (or build.gradle.kts):
   - Update applicationId if desired
   - Ensure minSdkVersion is 28 (Android 9, matching Pixel 9 support)
   - Set targetSdkVersion to 34 or 35 (latest stable)
   - Keep target platform as android-arm64 only (Pixel 9 is arm64)

B) In AndroidManifest.xml:
   - Ensure INTERNET permission exists (for VNC)
   - Add FOREGROUND_SERVICE permission (keeps container alive)
   - Consider adding: `<uses-feature android:name="android.hardware.touchscreen" />`

### 2.3 build.ps1 / Build Script

Update the build command documentation:
```
flutter build apk --target-platform android-arm64 --split-per-abi
```

## PHASE 3: SHELL SCRIPTS AND PATCHES

### 3.1 assets/patch.tar.gz Contents

The patch tarball is applied after rootfs extraction. Create a new patch structure:

```
patch/
├── etc/
│   ├── pacman.conf          # Optimized pacman config
│   ├── pacman.d/
│   │   └── mirrorlist       # Arch Linux ARM mirrors
│   ├── locale.conf          # LANG=en_US.UTF-8
│   ├── locale.gen           # en_US.UTF-8 UTF-8 (uncommented)
│   ├── X11/
│   │   └── xinit/
│   │       └── xinitrc      # Desktop environment launcher
│   └── sudoers.d/
│       └── tiny             # tiny ALL=(ALL) NOPASSWD: ALL
├── home/
│   └── tiny/
│       ├── .bashrc          # Custom bashrc with aliases
│       ├── .xinitrc          # User-level X init
│       └── .vnc/
│           └── xstartup     # VNC desktop launcher
└── usr/
    └── local/
        └── bin/
            ├── start-vnc.sh     # VNC start script
            ├── start-novnc.sh   # noVNC start script
            └── setup-arch.sh    # First-run initialization
```

### 3.2 Key Script Contents

A) start-vnc.sh:
```bash
#!/bin/bash
export DISPLAY=:4
export HOME=/home/tiny
vncserver :4 -geometry 2424x1080 -depth 24 -SecurityTypes None
```

B) start-novnc.sh:
```bash
#!/bin/bash
/usr/share/novnc/utils/novnc_proxy --vnc localhost:5904 --listen 36082 &
```

C) setup-arch.sh (first-run initialization):
```bash
#!/bin/bash
# Initialize pacman keyring
pacman-key --init
pacman-key --populate archlinuxarm
# Update system
pacman -Syu --noconfirm
# Install desktop environment
pacman -S --noconfirm xfce4 xfce4-goodies tigervnc novnc \
    firefox noto-fonts noto-fonts-cjk ttf-dejavu \
    sudo base-devel git wget curl
# Create user if not exists
id tiny &>/dev/null || useradd -m -G wheel -s /bin/bash tiny
echo "tiny:tiny" | chpasswd
# Enable sudo for wheel group
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
# Generate locale
sed -i 's/#en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

D) xinitrc (for X session startup):
```bash
#!/bin/bash
exec startxfce4
```

## PHASE 4: DOCUMENTATION

### 4.1 README.md

Rewrite the README entirely:
- Title: "DaRipped Tiny Computer — Arch Linux Edition"
- Description: One-click Arch Linux desktop on Android, optimized for Pixel 9
- Remove all Chinese-language-first documentation
- Make English the primary language
- Document Shizuku/rish integration
- Add Pixel 9 specific optimization notes
- Keep credits to upstream Cateners/tiny_computer

### 4.2 extra/build-tiny-rootfs.md

Replace the Debian rootfs build instructions with Arch Linux ARM rootfs
build instructions (see Phase 5 below for the complete procedure).

## PHASE 5: ARCH LINUX ARM ROOTFS BUILD PROCEDURE

Document these steps in extra/build-arch-rootfs.md:

1. Download the Arch Linux ARM generic aarch64 rootfs:
   `wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz`

2. Extract to a working directory (requires root on build machine):
   ```
   mkdir archroot && cd archroot
   sudo tar xzf ../ArchLinuxARM-aarch64-latest.tar.gz
   ```

3. Configure inside chroot (using qemu-user-static for cross-arch):
   ```
   sudo systemd-nspawn -D . /bin/bash
   # OR: sudo arch-chroot . /bin/bash (if on Arch build host)
   ```

4. Inside chroot, run the setup-arch.sh script contents from Phase 3.

5. Apply noVNC patches (same patches from upstream, adapted paths).

6. Clean up:
   ```
   pacman -Scc --noconfirm
   rm -rf /var/cache/pacman/pkg/*
   rm -rf /tmp/*
   rm -f /home/tiny/.bash_history /root/.bash_history
   ```

7. Package:
   ```
   cd /
   tar -Jcpf /archlinux.tar.xz \
     --exclude=dev --exclude=proc --exclude=sys \
     --exclude=archlinux.tar.xz /
   ```

8. Split for APK bundling:
   ```
   split -b 98M archlinux.tar.xz
   ```

9. Copy split files (xaa, xab, etc.) to the Flutter project's assets/ directory.

## CONSTRAINTS

- Do NOT modify the proot binary or busybox — they are distro-agnostic
- Do NOT modify the getifaddrs_bridge — it works at the syscall level
- Do NOT remove the noVNC patching infrastructure — the resolution slider
  and other UI patches are valuable
- PRESERVE the ability to use Termux:X11 and AVNC as display alternatives
- PRESERVE the split-chunk extraction logic (just update naming)
- ALL pacman commands in Dart must include --noconfirm to avoid TTY prompts
- The Pixel 9 runs Android 14+ with Tensor G4 — ensure minSdkVersion >= 28
- Shizuku integration must be OPTIONAL — the app must work without it

## TESTING CHECKLIST

After making changes, verify:
- [ ] Flutter project compiles: `flutter build apk --target-platform android-arm64`
- [ ] No remaining references to "debian" in lib/*.dart (except comments/attribution)
- [ ] No remaining apt/dpkg commands in lib/*.dart
- [ ] All user-facing strings updated in l10n/
- [ ] README.md is rewritten for Arch Linux
- [ ] build-arch-rootfs.md exists with complete instructions
- [ ] patch.tar.gz structure documented for Arch paths

Create a PR titled: "feat: Convert from Debian to Arch Linux ARM with Pixel 9 optimizations"
PR description should summarize all changes by phase.
```

---

## 3. Prompt 2: gemini-cli (Desktop — CachyOS)

This prompt is for running `gemini-cli` on your CachyOS desktop with KDE Plasma. Since gemini-cli has direct filesystem access and can execute shell commands, this prompt leverages your desktop's full build toolchain (Flutter SDK, Android SDK, git, etc.).

### How to Use

1. Open Konsole on your CachyOS desktop
2. Navigate to your cloned repo: `cd ~/repos/DaRipped_tiny_computer` (adjust path)
3. Run: `gemini -p "$(cat prompt-gemini-desktop.md)"` or paste into an interactive session
4. gemini-cli will read files, make edits, and run builds directly

### The Prompt

```
# SYSTEM CONTEXT

You are working on a local clone of https://github.com/DaRipper91/DaRipped_tiny_computer
on a CachyOS Linux desktop with KDE Plasma. The user has Flutter SDK, Android SDK,
git, and standard development tools available. The repo is a Flutter Android app
that runs a Debian proot container on Android.

YOUR MISSION: Convert this project from Debian-based to Arch Linux ARM-based,
optimized for Google Pixel 9 with Shizuku/rish support.

# STEP-BY-STEP EXECUTION PLAN

Execute these steps in order. After each step, show me what you changed and wait
for confirmation before proceeding.

## STEP 1: RECONNAISSANCE

Read and summarize the following files to understand the current architecture:
- lib/workflow.dart (the core logic — find ALL shell commands, ALL path references)
- lib/main.dart (UI — find all user-facing strings mentioning Debian)
- lib/l10n/ (all localization files — list all Debian references)
- pubspec.yaml (app metadata)
- android/app/build.gradle or build.gradle.kts (build config)
- android/app/src/main/AndroidManifest.xml (permissions)
- extra/build-tiny-rootfs.md (current rootfs build process)
- extra/readme.md (asset documentation)
- assets/ (list all files to understand the rootfs chunk layout)

For workflow.dart specifically, produce a COMPLETE LIST of:
1. Every shell command string (grep for patterns: "apt", "dpkg", "debian",
   "sources.list", "aarch64-linux-gnu", "tmoe", "Xsession")
2. Every file path that is Debian-specific
3. Every environment variable that references Debian/locale
4. The exact proot launch command and all its arguments
5. The rootfs extraction sequence (how chunks are reassembled)

Do NOT make any changes yet. Just report findings.

## STEP 2: CREATE ARCH ROOTFS BUILD SCRIPT

Create a new file: `extra/build-arch-rootfs.sh`

This script should be executable on this CachyOS machine and produce a complete
Arch Linux ARM rootfs tarball ready for the app. The script must:

1. Download ArchLinuxARM-aarch64-latest.tar.gz
2. Extract it into a working directory
3. Use systemd-nspawn (available on CachyOS) to configure it:
   - Initialize pacman keyring
   - Install: xfce4 xfce4-goodies tigervnc novnc python-websockify
     firefox noto-fonts noto-fonts-cjk ttf-dejavu sudo base-devel
     git wget curl bash-completion htop neofetch nano vim
   - Create user 'tiny' with password 'tiny', add to wheel group
   - Configure sudoers: wheel group NOPASSWD
   - Generate en_US.UTF-8 locale
   - Create /etc/X11/xinit/xinitrc that runs startxfce4
   - Create VNC startup scripts at /usr/local/bin/
   - Set VNC display to :4 (port 5904) and noVNC to port 36082
   - Apply noVNC patches if available
   - Clean package cache, temp files, shell histories
4. Package as archlinux.tar.xz (using tar with --exclude for dev,proc,sys)
5. Split into 98MB chunks
6. Report total size and chunk count

Also create `extra/build-arch-rootfs.md` documenting the manual process.

## STEP 3: MODIFY workflow.dart

Using the findings from Step 1, make ALL the following substitutions.
Use sed or direct file editing. Show each change with before/after context.

Package manager commands (find the exact strings from Step 1 and replace):
- Every `apt update` → `pacman -Sy`
- Every `apt upgrade` or `apt full-upgrade` → `pacman -Syu --noconfirm`
- Every `apt install` → `pacman -S --noconfirm`
- Every `apt remove` or `apt purge` → `pacman -Rns --noconfirm`
- Every `apt clean` or `apt autoclean` → `pacman -Scc --noconfirm`
- Every `apt autoremove` → `pacman -Qdtq | pacman -Rns --noconfirm -`
- Every `dpkg -i` → `pacman -U --noconfirm`
- Every `dpkg --configure` → remove entirely

File paths:
- Every `/usr/lib/aarch64-linux-gnu/` → `/usr/lib/`
- Every `/etc/apt/sources.list` → `/etc/pacman.d/mirrorlist`
- Every `/usr/local/etc/tmoe-linux/` → remove or replace with `/usr/local/etc/`
- Every `/etc/X11/xinit/Xsession` → `/etc/X11/xinit/xinitrc`
- Every reference to `debian.tar.xz` → `archlinux.tar.xz`

Environment variables:
- Default LANG from `zh_CN.UTF-8` to `en_US.UTF-8`

Add Shizuku detection method (add to the Util class or appropriate location):
```dart
static Future<bool> isShizukuAvailable() async {
  try {
    final result = await Process.run('sh', ['-c', 'command -v rish']);
    return result.exitCode == 0;
  } catch (e) {
    return false;
  }
}

static Future<ProcessResult> executeViaRish(String command) async {
  return await Process.run('rish', ['-c', command]);
}
```

Add a Shizuku preference toggle to the G (globals) class.

## STEP 4: MODIFY main.dart

Update all user-facing text:
- Replace "Debian" with "Arch Linux" in all UI strings
- Replace "debian" with "archlinux" in technical displays
- Add Shizuku toggle in settings panel
- Update default resolution suggestions for Pixel 9:
  - Width: 2424, Height: 1080 (or allow 1080x2424 for portrait)
  - DPI: 420

## STEP 5: UPDATE LOCALIZATION FILES

In lib/l10n/, update every localization file:
- Replace all "Debian" references with "Arch Linux"
- Replace all apt command examples with pacman equivalents
- Ensure English (en) is complete and primary
- Update Chinese (zh) translations to match

## STEP 6: UPDATE BUILD CONFIGURATION

A) pubspec.yaml:
   - Update description to reference Arch Linux
   - Bump version to 2.0.0+1

B) android/app/build.gradle:
   - Ensure minSdkVersion >= 28
   - Ensure targetSdkVersion is 34 or 35
   - Verify only arm64-v8a ABI is targeted

C) AndroidManifest.xml:
   - Verify INTERNET permission present
   - Add FOREGROUND_SERVICE if missing
   - Add FOREGROUND_SERVICE_SPECIAL_USE if targeting API 34+

## STEP 7: UPDATE DOCUMENTATION

A) Rewrite README.md:
   - English-first documentation
   - Title: "DaRipped Tiny Computer — Arch Linux Edition"
   - Document: installation, usage, Shizuku integration, Pixel 9 optimization
   - Credit upstream Cateners/tiny_computer
   - Remove Chinese-first formatting (keep Chinese as secondary)

B) Create extra/build-arch-rootfs.md with the rootfs build procedure

C) Update extra/readme.md to document new asset structure

## STEP 8: VALIDATE

Run these validation checks and report results:
```bash
# Check for remaining Debian references in Dart source
grep -rn "debian\|apt install\|apt update\|dpkg\|sources\.list\|aarch64-linux-gnu\|tmoe\|Xsession" lib/ --include="*.dart"

# Check Flutter compilation
flutter analyze
flutter build apk --target-platform android-arm64 --split-per-abi --debug 2>&1 | tail -20

# Check localization completeness
grep -rn "Debian" lib/l10n/
```

Report any remaining issues.

## STEP 9: GIT COMMIT

Stage and commit all changes:
```bash
git checkout -b feature/arch-linux-conversion
git add -A
git commit -m "feat: Convert from Debian to Arch Linux ARM

- Replace all apt/dpkg commands with pacman equivalents
- Update all file paths from Debian to Arch Linux conventions
- Add Shizuku/rish integration for Pixel 9 optimization
- Create Arch Linux ARM rootfs build script and documentation
- Update UI strings and localization for Arch Linux
- Set default locale to en_US.UTF-8
- Add Pixel 9 display optimization defaults
- Rewrite README for English-first Arch Linux documentation"
```

# IMPORTANT CONSTRAINTS

- The proot, busybox, and getifaddrs_bridge binaries must NOT be modified
- The noVNC patch infrastructure must be preserved
- Termux:X11 and AVNC display support must be preserved
- The split-chunk rootfs extraction logic stays (just rename references)
- ALL pacman commands must include --noconfirm
- Shizuku support must be OPTIONAL (graceful fallback)
- Do not break the Flutter build — test compilation at each major step
```

---

## 4. Prompt 3: gemini-cli-termux (Mobile — Pixel 9)

This prompt is for running gemini-cli inside Termux on your Pixel 9. Since this environment has limited resources, the prompt focuses on tasks that make sense on-device: building the Arch rootfs, testing proot execution, validating configurations, and iterating on shell scripts. It assumes Shizuku is active and `rish` is available.

### How to Use

1. Open Termux on your Pixel 9
2. Ensure gemini-cli-termux is installed and configured
3. Navigate to or clone the repo within Termux
4. Run the prompt interactively or pipe it

### The Prompt

```
# CONTEXT: TERMUX ON PIXEL 9 (NON-ROOT, SHIZUKU ACTIVE)

You are running inside Termux on a Google Pixel 9. The device is non-rooted
but Shizuku is installed and active, providing `rish` for ADB-level shell access.
gemini-cli-termux is the active tool. Termux has access to the filesystem
at /data/data/com.termux/files/home/ and shared storage at ~/storage/.

The goal is to build and test the Arch Linux ARM proot container that will be
used by the DaRipped_tiny_computer Flutter app. This prompt handles the
ON-DEVICE work: rootfs creation, proot testing, script validation.

# PREREQUISITE CHECK

First, verify the environment. Run these and report results:

```bash
# Check architecture
uname -m
# Should be: aarch64

# Check Termux packages
pkg list-installed 2>/dev/null | grep -E "proot|wget|tar|xz"

# Check Shizuku/rish availability
command -v rish && echo "rish available" || echo "rish NOT found"
rish -c "id" 2>/dev/null

# Check available storage
df -h /data/data/com.termux/files/home/
df -h ~/storage/shared/

# Check proot-distro availability
command -v proot-distro && echo "proot-distro available" || echo "Install: pkg install proot-distro"
```

Install anything missing:
```bash
pkg update && pkg install proot proot-distro wget tar xz-utils git vim nano
```

# PHASE 1: CREATE ARCH LINUX ARM ROOTFS VIA PROOT-DISTRO

proot-distro already supports Arch Linux ARM. We will use it as the base,
then customize for tiny_computer compatibility.

## Step 1.1: Install Arch Linux via proot-distro

```bash
proot-distro install archlinux
```

## Step 1.2: Login and configure

```bash
proot-distro login archlinux -- /bin/bash
```

Inside the Arch container, execute:

```bash
# Initialize keyring
pacman-key --init
pacman-key --populate archlinuxarm

# Full system update
pacman -Syu --noconfirm

# Install desktop environment and core packages
pacman -S --noconfirm \
    xfce4 xfce4-goodies \
    tigervnc \
    python python-websockify python-numpy \
    firefox \
    noto-fonts noto-fonts-cjk ttf-dejavu \
    sudo base-devel git wget curl \
    bash-completion htop neofetch nano vim \
    xdg-utils xdg-user-dirs \
    dbus

# Install noVNC from AUR or manually:
# Option A: Manual install (more reliable in proot)
cd /tmp
git clone https://github.com/novnc/noVNC.git /usr/share/novnc
ln -s /usr/share/novnc/vnc.html /usr/share/novnc/index.html

# Create user 'tiny'
useradd -m -G wheel -s /bin/bash tiny
echo "tiny:tiny" | chpasswd

# Configure sudoers
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Configure locale
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Create X session startup
cat > /etc/X11/xinit/xinitrc << 'XINITRC'
#!/bin/bash
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
exec startxfce4
XINITRC
chmod +x /etc/X11/xinit/xinitrc

# Create user xinitrc
su - tiny -c 'cat > ~/.xinitrc << "EOF"
#!/bin/bash
exec startxfce4
EOF
chmod +x ~/.xinitrc'

# Create VNC startup script
cat > /usr/local/bin/start-vnc << 'VNCSCRIPT'
#!/bin/bash
export USER=tiny
export HOME=/home/tiny
export DISPLAY=:4

# Kill existing VNC session if running
vncserver -kill :4 2>/dev/null || true

# Set VNC password (non-interactive)
mkdir -p /home/tiny/.vnc
echo "12345678" | vncpasswd -f > /home/tiny/.vnc/passwd
chmod 600 /home/tiny/.vnc/passwd
chown -R tiny:tiny /home/tiny/.vnc

# Create xstartup
cat > /home/tiny/.vnc/xstartup << 'XSTARTUP'
#!/bin/bash
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
exec startxfce4
XSTARTUP
chmod +x /home/tiny/.vnc/xstartup

# Start VNC
su - tiny -c "vncserver :4 -geometry 2424x1080 -depth 24 -localhost no"
VNCSCRIPT
chmod +x /usr/local/bin/start-vnc

# Create noVNC startup script
cat > /usr/local/bin/start-novnc << 'NOVNCSCRIPT'
#!/bin/bash
/usr/share/novnc/utils/novnc_proxy \
    --vnc localhost:5904 \
    --listen 36082 \
    --web /usr/share/novnc &
echo "noVNC running on http://localhost:36082/vnc.html"
NOVNCSCRIPT
chmod +x /usr/local/bin/start-novnc

# Create a combined start script
cat > /usr/local/bin/start-desktop << 'STARTALL'
#!/bin/bash
echo "Starting VNC server..."
start-vnc
sleep 2
echo "Starting noVNC..."
start-novnc
echo ""
echo "=== Desktop Ready ==="
echo "VNC:   localhost:5904"
echo "noVNC: http://localhost:36082/vnc.html"
echo "Password: 12345678"
STARTALL
chmod +x /usr/local/bin/start-desktop
```

## Step 1.3: Test the desktop

```bash
# Still inside the Arch proot container:
start-desktop
```

Verify you can connect via a VNC client or browser to localhost:36082.

## Step 1.4: Optimize for Pixel 9

```bash
# Inside Arch container:

# Pixel 9 has a Tensor G4 with 12GB RAM — configure accordingly
# Allow larger VNC framebuffer
# Set XFCE to use compositing OFF (proot doesn't have GPU access)
su - tiny -c 'xfconf-query -c xfwm4 -p /general/use_compositing -s false' 2>/dev/null || true

# Reduce XFCE panel sizes for mobile screens
# These will be applied on first desktop launch

# Configure pacman for parallel downloads (Pixel 9 has good bandwidth)
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

# Enable Color in pacman output
sed -i 's/#Color/Color/' /etc/pacman.conf
```

## Step 1.5: Clean and package

```bash
# Inside Arch container:
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*
rm -rf /tmp/*
rm -f /home/tiny/.bash_history /root/.bash_history
rm -rf /home/tiny/.cache/*
rm -f /home/tiny/.vnc/*.log /home/tiny/.vnc/*.pid
exit
```

## Step 1.6: Export the rootfs

```bash
# Back in Termux (not in proot container):

# The proot-distro rootfs lives at:
ARCHROOT="$PREFIX/var/lib/proot-distro/installed-rootfs/archlinux"

# Package it (this will take a while on-device)
cd $ARCHROOT

# Use rish for faster I/O if available:
if command -v rish &>/dev/null; then
    echo "Using rish for elevated tar operation..."
    rish -c "cd $ARCHROOT && tar -Jcpf /data/local/tmp/archlinux.tar.xz \
        --exclude=dev --exclude=proc --exclude=sys \
        --exclude=archlinux.tar.xz ."
    cp /data/local/tmp/archlinux.tar.xz ~/archlinux.tar.xz
else
    echo "Using standard tar (slower)..."
    tar -Jcpf ~/archlinux.tar.xz \
        --exclude=dev --exclude=proc --exclude=sys \
        --exclude=archlinux.tar.xz .
fi

# Check size
ls -lh ~/archlinux.tar.xz

# Split into 98MB chunks for APK bundling
cd ~
split -b 98M archlinux.tar.xz archlinux_chunk_
ls -lh archlinux_chunk_*

echo "Total chunks: $(ls archlinux_chunk_* | wc -l)"
echo "Total size: $(du -sh archlinux.tar.xz | cut -f1)"
```

## Step 1.7: Transfer chunks to build machine

```bash
# Copy to shared storage for easy transfer
mkdir -p ~/storage/shared/DaRipped_build/
cp archlinux_chunk_* ~/storage/shared/DaRipped_build/
cp archlinux.tar.xz ~/storage/shared/DaRipped_build/

echo "Files available at: /storage/emulated/0/DaRipped_build/"
echo "Transfer to your CachyOS desktop via:"
echo "  adb pull /storage/emulated/0/DaRipped_build/ ~/repos/DaRipped_tiny_computer/assets/"
echo "  OR use KDE Connect file transfer"
echo "  OR use scp/rsync over local network"
```

# PHASE 2: VALIDATE PROOT OPERATION

Test that the rootfs works correctly under proot conditions similar to
how the Flutter app will use it.

```bash
# Test proot launch with the same flags the Flutter app uses:
proot \
    --link2symlink \
    --kill-on-exit \
    --root-id \
    --bind=/dev \
    --bind=/proc \
    --bind=/sys \
    --rootfs=$ARCHROOT \
    /usr/bin/env -i \
    HOME=/home/tiny \
    USER=tiny \
    LANG=en_US.UTF-8 \
    TERM=xterm-256color \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    DISPLAY=:4 \
    /bin/su - tiny -c "echo 'Arch proot works!' && uname -a && pacman --version"
```

# PHASE 3: TEST SHIZUKU INTEGRATION

```bash
# Verify rish works for the operations we need:

# Test 1: Process priority (nice level)
rish -c "renice -n -5 -p $$" 2>&1

# Test 2: Access /data/local/tmp/
rish -c "ls -la /data/local/tmp/" 2>&1

# Test 3: Write test file to /data/local/tmp/
rish -c "echo 'shizuku_test' > /data/local/tmp/daripped_test && cat /data/local/tmp/daripped_test && rm /data/local/tmp/daripped_test" 2>&1

# Test 4: Check if we can set CPU affinity (Pixel 9 big.LITTLE cores)
rish -c "taskset -p $$" 2>&1

echo ""
echo "=== Shizuku Integration Summary ==="
echo "If tests above succeeded, the Flutter app can use rish for:"
echo "  - Faster rootfs extraction via /data/local/tmp/"
echo "  - Process priority boosting for proot"
echo "  - CPU core affinity for performance cores"
```

# OUTPUT SUMMARY

After completing all phases, report:
1. Arch rootfs total size (compressed)
2. Number of 98MB chunks
3. List of installed packages and their sizes (pacman -Qi | grep "Installed Size")
4. VNC test result (did the desktop start?)
5. Shizuku test results
6. Any errors or warnings encountered
7. Estimated APK size increase/decrease vs Debian version
```

---

## 5. Prompt 4: claude-cli (Claude Code)

Claude Code (claude-cli) excels at understanding entire codebases, making precise multi-file edits, and maintaining consistency across changes. This prompt leverages Claude Code's strength in code comprehension and refactoring.

### How to Use

1. Open terminal on your CachyOS desktop (or Termux with claude-cli)
2. Navigate to the repo: `cd ~/repos/DaRipped_tiny_computer`
3. Run: `claude` to start an interactive session
4. Paste the prompt below, or save it as a file and reference it

### The Prompt

```
I need you to convert the DaRipped_tiny_computer Flutter Android app from
Debian-based to Arch Linux ARM-based. This is a fork of Cateners/tiny_computer
that runs a proot Linux container on Android with a desktop environment.

The target device is a Google Pixel 9 (non-root, with Shizuku/rish available
for ADB-level shell access).

## YOUR APPROACH

You have full filesystem access to this repo. I want you to:

1. FIRST: Read and deeply understand the codebase before making ANY changes.
   Read these files completely:
   - lib/workflow.dart (THE most critical file — all container logic)
   - lib/main.dart (UI layer)
   - Every file in lib/l10n/
   - pubspec.yaml
   - android/app/build.gradle (or .kts variant)
   - android/app/src/main/AndroidManifest.xml
   - extra/build-tiny-rootfs.md
   - extra/readme.md
   - README.md

2. THEN: Create a detailed analysis report listing EVERY instance of:
   - Debian-specific shell commands (apt, dpkg, etc.) with exact line numbers
   - Debian-specific file paths with exact line numbers
   - tmoe-specific references with exact line numbers
   - Hardcoded Debian environment variables
   - User-facing strings mentioning "Debian" or "debian"
   
   Show me this report and wait for my confirmation before proceeding.

3. AFTER MY CONFIRMATION: Execute the conversion systematically.

## CONVERSION RULES

### Package Manager Translation Table
| Debian (find & replace) | Arch Linux (replacement) |
|---|---|
| `apt update` | `pacman -Sy` |
| `apt upgrade` | `pacman -Syu --noconfirm` |
| `apt full-upgrade` | `pacman -Syu --noconfirm` |
| `apt install <pkgs>` | `pacman -S --noconfirm <pkgs>` |
| `apt remove <pkgs>` | `pacman -Rns --noconfirm <pkgs>` |
| `apt purge <pkgs>` | `pacman -Rns --noconfirm <pkgs>` |
| `apt autoremove` | `pacman -Qdtq \| pacman -Rns --noconfirm -` |
| `apt clean` | `pacman -Scc --noconfirm` |
| `apt autoclean` | `pacman -Scc --noconfirm` |
| `apt list --installed` | `pacman -Q` |
| `apt search <term>` | `pacman -Ss <term>` |
| `apt show <pkg>` | `pacman -Si <pkg>` |
| `dpkg -i <file.deb>` | `pacman -U --noconfirm <file.pkg.tar.zst>` |
| `dpkg --configure -a` | (remove — not applicable) |
| `dpkg -l` | `pacman -Q` |

### Package Name Translation Table
| Debian Package | Arch Linux Package |
|---|---|
| firefox-esr | firefox |
| firefox-esr-l10n-zh-cn | firefox-i18n-zh-cn |
| build-essential | base-devel |
| python3 | python |
| python3-pip | python-pip |
| libgtk-3-dev | gtk3 |
| vim-gtk3 | gvim |
| gdebi | (remove — use pacman -U instead) |
| ttf-mscorefonts-installer | (AUR: ttf-ms-fonts, or skip) |
| xfce4-terminal | xfce4-terminal (same) |
| tigervnc-standalone-server | tigervnc |
| task-xfce-desktop | xfce4 xfce4-goodies |
| fonts-noto | noto-fonts |
| fonts-noto-cjk | noto-fonts-cjk |

### Path Translation Table
| Debian Path | Arch Linux Path |
|---|---|
| /usr/lib/aarch64-linux-gnu/ | /usr/lib/ |
| /etc/apt/sources.list | /etc/pacman.d/mirrorlist |
| /etc/apt/ | /etc/pacman.d/ |
| /usr/local/etc/tmoe-linux/ | (remove all references) |
| /etc/X11/xinit/Xsession | /etc/X11/xinit/xinitrc |
| /var/cache/apt/ | /var/cache/pacman/pkg/ |
| /etc/debian_version | /etc/arch-release |

### Environment Variable Changes
| Variable | Old Value | New Value |
|---|---|---|
| LANG | zh_CN.UTF-8 | en_US.UTF-8 |

## SHIZUKU/RISH INTEGRATION

Add the following capabilities (all must be optional with graceful fallback):

1. **Detection**: Check if `rish` command exists at runtime
2. **Fast extraction**: If Shizuku available, use `rish -c "tar ..."` to extract
   rootfs to /data/local/tmp/ first (faster I/O), then move to app data dir
3. **Process priority**: Use `rish -c "renice -n -5 -p <pid>"` to boost proot
4. **Settings toggle**: Add "Enhanced Performance (Shizuku)" toggle in settings UI
5. **Status indicator**: Show "Shizuku: Active/Inactive" in container info panel

Implementation approach for Dart:
```dart
class ShizukuHelper {
  static bool _available = false;
  
  static Future<void> init() async {
    try {
      final result = await Process.run('sh', ['-c', 'command -v rish']);
      _available = result.exitCode == 0;
    } catch (_) {
      _available = false;
    }
  }
  
  static bool get isAvailable => _available;
  
  static Future<ProcessResult> run(String command) async {
    if (!_available) {
      return Process.run('sh', ['-c', command]);
    }
    return Process.run('rish', ['-c', command]);
  }
}
```

## PIXEL 9 OPTIMIZATIONS

1. Default VNC resolution: 2424x1080 (native Pixel 9 width × reasonable height)
2. Default DPI: 420
3. Compositor disabled by default (no GPU in proot)
4. ParallelDownloads = 5 in pacman.conf (Pixel 9 has good connectivity)

## NEW FILES TO CREATE

1. `extra/build-arch-rootfs.md` — Complete Arch rootfs build documentation
2. `extra/build-arch-rootfs.sh` — Automated rootfs build script
3. Update `extra/readme.md` — Document new asset structure

## FILES TO REWRITE

1. `README.md` — Complete rewrite:
   - English-first (Chinese as secondary section)
   - Title: "DaRipped Tiny Computer — Arch Linux Edition"
   - Sections: Features, Download, How It Works, Pixel 9 Setup,
     Shizuku Integration, Building from Source, Known Issues, Credits
   - Credit Cateners/tiny_computer as upstream

## VERIFICATION

After all changes, run:
```bash
# Scan for any remaining Debian artifacts
grep -rn --include="*.dart" -E "apt |apt-get|dpkg|debian|sources\.list|aarch64-linux-gnu|tmoe|Xsession" lib/

# Scan for Debian in localization
grep -rn --include="*.arb" -i "debian" lib/l10n/

# Flutter analysis
flutter analyze

# Attempt build (will fail without rootfs assets, but Dart compilation should succeed)
flutter build apk --target-platform android-arm64 --split-per-abi 2>&1 | head -50
```

## COMMIT STRATEGY

Make changes in logical commits:
1. `refactor: Replace all apt/dpkg commands with pacman equivalents`
2. `refactor: Update all Debian paths to Arch Linux paths`
3. `feat: Add Shizuku/rish integration for Pixel 9`
4. `feat: Add Pixel 9 display optimizations`
5. `docs: Rewrite README and add Arch rootfs build documentation`
6. `chore: Update build configuration and localization`

Each commit should leave the project in a compilable state.
```

---

## 6. Shared Reference: File-by-File Modification Map

This reference applies to all four prompts. It maps every file that needs changes and what changes are needed.

| File | Change Type | Description |
|---|---|---|
| `lib/workflow.dart` | **Heavy edit** | Replace ALL apt/dpkg commands, ALL Debian paths, ALL tmoe references, add Shizuku methods |
| `lib/main.dart` | **Moderate edit** | Update UI strings, add Shizuku toggle, add Pixel 9 defaults |
| `lib/l10n/*.arb` | **Moderate edit** | Update all Debian→Arch references in every locale file |
| `pubspec.yaml` | **Light edit** | Update description, version |
| `android/app/build.gradle` | **Light edit** | Verify SDK versions, ABI filter |
| `android/app/src/main/AndroidManifest.xml` | **Light edit** | Verify permissions |
| `README.md` | **Full rewrite** | English-first Arch Linux documentation |
| `extra/build-tiny-rootfs.md` | **Deprecate** | Keep for reference, add note pointing to new file |
| `extra/build-arch-rootfs.md` | **New file** | Arch rootfs build documentation |
| `extra/build-arch-rootfs.sh` | **New file** | Automated rootfs build script |
| `extra/readme.md` | **Moderate edit** | Update asset documentation |
| `build.ps1` | **Light edit** | Update comments/documentation |
| `assets/*` | **Replace** | New rootfs chunks (done manually, not by AI) |

### Files That Must NOT Be Modified

| File/Directory | Reason |
|---|---|
| `android/app/src/main/jniLibs/` | proot, busybox, getifaddrs_bridge are distro-agnostic |
| `.github/` | Issue templates can stay as-is |
| `COPYING` | GPL-3.0 license unchanged |
| `OWNERS` | Upstream attribution |

---

## 7. Shared Reference: Arch Linux ARM rootfs Build Script

This is the complete build script referenced by multiple prompts. Save as `extra/build-arch-rootfs.sh`:

```bash
#!/bin/bash
set -euo pipefail

# =============================================================================
# build-arch-rootfs.sh — Build Arch Linux ARM rootfs for DaRipped tiny_computer
# =============================================================================
# Prerequisites: 
#   - Arch Linux or CachyOS host (for systemd-nspawn + pacstrap)
#   - OR: any Linux with qemu-user-static-binfmt for cross-arch
#   - Root/sudo access on the build machine
#   - ~8GB free disk space
#
# Usage: sudo ./build-arch-rootfs.sh [--xfce|--lxqt] [--split-size SIZE]
# =============================================================================

DE="${1:---xfce}"
SPLIT_SIZE="${2:-98M}"
WORKDIR="$(pwd)/archroot-build"
ROOTFS="$WORKDIR/rootfs"
OUTPUT="$WORKDIR/output"

echo "=== DaRipped Arch Linux ARM rootfs Builder ==="
echo "Desktop: $DE"
echo "Split size: $SPLIT_SIZE"
echo "Working directory: $WORKDIR"
echo ""

# Step 1: Download Arch Linux ARM rootfs
echo "[1/8] Downloading Arch Linux ARM rootfs..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"
if [ ! -f ArchLinuxARM-aarch64-latest.tar.gz ]; then
    wget -c http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz
fi

# Step 2: Extract base rootfs
echo "[2/8] Extracting base rootfs..."
mkdir -p "$ROOTFS"
sudo tar xzf ArchLinuxARM-aarch64-latest.tar.gz -C "$ROOTFS"

# Step 3: Configure inside container
echo "[3/8] Configuring system inside container..."
sudo systemd-nspawn -D "$ROOTFS" --bind-ro=/etc/resolv.conf /bin/bash -c '
    # Initialize pacman
    pacman-key --init
    pacman-key --populate archlinuxarm
    
    # Enable parallel downloads and color
    sed -i "s/#ParallelDownloads = 5/ParallelDownloads = 5/" /etc/pacman.conf
    sed -i "s/#Color/Color/" /etc/pacman.conf
    
    # Full system update
    pacman -Syu --noconfirm
'

# Step 4: Install desktop environment
echo "[4/8] Installing desktop environment..."
if [ "$DE" = "--xfce" ] || [ "$DE" = "xfce" ]; then
    DESKTOP_PKGS="xfce4 xfce4-goodies xfce4-terminal"
elif [ "$DE" = "--lxqt" ] || [ "$DE" = "lxqt" ]; then
    DESKTOP_PKGS="lxqt openbox"
else
    echo "Unknown DE: $DE (use --xfce or --lxqt)"
    exit 1
fi

sudo systemd-nspawn -D "$ROOTFS" --bind-ro=/etc/resolv.conf /bin/bash -c "
    pacman -S --noconfirm \
        $DESKTOP_PKGS \
        tigervnc \
        python python-websockify python-numpy \
        firefox \
        noto-fonts noto-fonts-cjk ttf-dejavu \
        sudo base-devel git wget curl \
        bash-completion htop neofetch nano vim \
        xdg-utils xdg-user-dirs dbus \
        xorg-server xorg-xinit xorg-xauth
"

# Step 5: Install noVNC
echo "[5/8] Installing noVNC..."
sudo systemd-nspawn -D "$ROOTFS" --bind-ro=/etc/resolv.conf /bin/bash -c '
    cd /tmp
    git clone --depth 1 https://github.com/novnc/noVNC.git /usr/share/novnc
    ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html
    rm -rf /usr/share/novnc/.git
'

# Step 6: Configure users, locale, scripts
echo "[6/8] Configuring users, locale, and startup scripts..."
sudo systemd-nspawn -D "$ROOTFS" /bin/bash -c '
    # Create user
    useradd -m -G wheel -s /bin/bash tiny
    echo "tiny:tiny" | chpasswd
    
    # Sudoers
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
    chmod 440 /etc/sudoers.d/wheel
    
    # Locale
    sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/" /etc/locale.gen
    locale-gen
    echo "LANG=en_US.UTF-8" > /etc/locale.conf
    
    # X session init
    cat > /etc/X11/xinit/xinitrc << "XINITRC"
#!/bin/bash
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
exec startxfce4
XINITRC
    chmod +x /etc/X11/xinit/xinitrc
    
    # User xinitrc
    su - tiny -c "cat > ~/.xinitrc << EOF
#!/bin/bash
exec startxfce4
EOF
chmod +x ~/.xinitrc"
    
    # VNC scripts
    cat > /usr/local/bin/start-vnc << "SCRIPT"
#!/bin/bash
export USER=tiny HOME=/home/tiny DISPLAY=:4
vncserver -kill :4 2>/dev/null || true
mkdir -p /home/tiny/.vnc
echo "12345678" | vncpasswd -f > /home/tiny/.vnc/passwd
chmod 600 /home/tiny/.vnc/passwd
chown -R tiny:tiny /home/tiny/.vnc
cat > /home/tiny/.vnc/xstartup << "XS"
#!/bin/bash
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
export XDG_SESSION_TYPE=x11 XDG_CURRENT_DESKTOP=XFCE
exec startxfce4
XS
chmod +x /home/tiny/.vnc/xstartup
su - tiny -c "vncserver :4 -geometry 2424x1080 -depth 24 -localhost no"
SCRIPT
    chmod +x /usr/local/bin/start-vnc
    
    cat > /usr/local/bin/start-novnc << "SCRIPT"
#!/bin/bash
/usr/share/novnc/utils/novnc_proxy --vnc localhost:5904 --listen 36082 --web /usr/share/novnc &
echo "noVNC: http://localhost:36082/vnc.html"
SCRIPT
    chmod +x /usr/local/bin/start-novnc
    
    cat > /usr/local/bin/start-desktop << "SCRIPT"
#!/bin/bash
echo "Starting VNC..."
start-vnc
sleep 2
echo "Starting noVNC..."
start-novnc
echo "Desktop ready — VNC :5904 / noVNC :36082"
SCRIPT
    chmod +x /usr/local/bin/start-desktop
'

# Step 7: Clean up
echo "[7/8] Cleaning up..."
sudo systemd-nspawn -D "$ROOTFS" /bin/bash -c '
    pacman -Scc --noconfirm
    rm -rf /var/cache/pacman/pkg/* /tmp/* /var/tmp/*
    rm -f /home/tiny/.bash_history /root/.bash_history
    rm -rf /home/tiny/.cache /root/.cache
    rm -f /home/tiny/.vnc/*.log /home/tiny/.vnc/*.pid
'

# Step 8: Package
echo "[8/8] Packaging rootfs..."
mkdir -p "$OUTPUT"
cd "$ROOTFS"
sudo tar -Jcpf "$OUTPUT/archlinux.tar.xz" \
    --exclude=dev --exclude=proc --exclude=sys \
    --exclude=archlinux.tar.xz .

cd "$OUTPUT"
split -b "$SPLIT_SIZE" archlinux.tar.xz

echo ""
echo "=== Build Complete ==="
echo "Rootfs: $OUTPUT/archlinux.tar.xz"
echo "Size: $(du -sh archlinux.tar.xz | cut -f1)"
echo "Chunks: $(ls x* 2>/dev/null | wc -l) files at $SPLIT_SIZE each"
echo ""
echo "Copy the x* files to your Flutter project's assets/ directory."
echo "Rename them to match the expected pattern (xaa, xab, xac, etc.)"
```

---

## 8. Shared Reference: Shizuku/rish Integration Points

These are the specific integration points for Shizuku/rish in the Flutter app, shared across all prompts:

### Detection Logic (Dart)
```dart
// Check if Shizuku is available by testing rish command
Future<bool> _checkShizuku() async {
  try {
    final result = await Process.run('sh', ['-c', 'command -v rish']);
    if (result.exitCode == 0) {
      // Verify it actually works
      final test = await Process.run('rish', ['-c', 'echo ok']);
      return test.exitCode == 0 && test.stdout.toString().trim() == 'ok';
    }
  } catch (_) {}
  return false;
}
```

### Use Cases for rish in tiny_computer
| Operation | Without Shizuku | With Shizuku (rish) |
|---|---|---|
| Rootfs extraction | `tar -xf` in app sandbox | `rish -c "tar -xf ..."` to /data/local/tmp/ (faster) |
| Process priority | Default niceness | `rish -c "renice -n -5 ..."` |
| File permissions | App sandbox only | Can access /data/local/tmp/ |
| CPU affinity | Not available | `rish -c "taskset ..."` for Tensor G4 big cores |
| Kill stuck processes | App process only | `rish -c "kill -9 ..."` for zombie cleanup |

### Settings Integration
```dart
// Add to settings/preferences:
// Key: 'use_shizuku'
// Default: false (auto-enable if detected on first run)
// UI: Switch toggle with status indicator
// Label: "Enhanced Performance (Shizuku)"
// Subtitle: Shows "Active" / "Not Available" / "Disabled"
```

---

*Document generated for DaRipper91/DaRipped_tiny_computer Arch Linux conversion project.*
