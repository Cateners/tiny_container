# DaRipped Tiny Computer — Master Manual

**Version 2.1.0 · Android ARM64 · Arch Linux ARM Edition**

---

## Table of Contents

1. [User Guide](#1-user-guide)
   - [What Is DaRipped Tiny Computer?](#11-what-is-daripped-tiny-computer)
   - [System Requirements](#12-system-requirements)
   - [The Bootstrap System](#13-the-bootstrap-system)
   - [Using the Desktop](#14-using-the-desktop)
   - [Intelligence & Knowledge Generation](#15-intelligence--knowledge-generation)
2. [Installation Guide](#2-installation-guide)
   - [Install from APK (End Users)](#21-install-from-apk-end-users)
   - [Permissions & Android 14 Hacks](#22-permissions--android-14-hacks)
3. [Customization Guide](#3-customization-guide)
   - [Hardware Acceleration (VirGL)](#31-hardware-acceleration-virgl)
   - [High-Fidelity Audio (PipeWire)](#32-high-fidelity-audio-pipewire)
   - [Display & HiDPI Scaling](#33-display--hidpi-scaling)
4. [Neural Workflow Reference](#4-neural-workflow-reference)
   - [The Intelligence Sink (to_vault)](#41-the-intelligence-sink-to_vault)
   - [Rust-based Parsing Stack](#42-rust-based-parsing-stack)
   - [Multiplexer Layout (Zellij)](#43-multiplexer-layout-zellij)
5. [Troubleshooting Guide](#5-troubleshooting-guide)
   - [Android 14 ptrace Denials](#51-android-14-ptrace-denials)
   - [Display Sync Timeouts](#52-display-sync-timeouts)
   - [Resetting the Environment](#53-resetting-the-environment)

---

## 1. User Guide

### 1.1 What Is DaRipped Tiny Computer?

DaRipped Tiny Computer is a high-performance **Arch Linux ARM workstation** running inside an Android userspace container. Unlike standard Linux-on-Android ports, this environment is architected for **intelligence and knowledge generation**, featuring kernel-level optimizations for the Tensor G4 processor.

### 1.2 System Requirements

| Requirement | Minimum | Recommended |
|---|---|---|
| OS | Android 10+ | Android 14+ |
| SOC | ARM64 | Tensor G4 (Pixel 9) |
| Storage | 4 GB | 16 GB+ (UFS 4.0) |
| RAM | 4 GB | 12 GB+ |

### 1.3 The Bootstrap System

Due to `systemd` being incompatible with PRoot, DaRipped utilizes a specialized two-stage initialization:
1. **`start-arch.sh`**: Initializes the D-Bus system bus, fixes permissions, and injects dynamic DNS from the Android host.
2. **`start-desktop`**: Synchronizes with the Termux:X11 display server and handles HiDPI scaling before launching XFCE4.

### 1.5 Intelligence & Knowledge Generation

The environment is pre-configured as a **Neural Processing Station**:
- **Structured Storage:** Built-in Obsidian-ready vault at `~/Vault`.
- **The Sink:** Use `to_vault` to pipe any CLI output directly into your knowledge graph with automatic metadata tagging.
- **Clipboard Bridge:** 1:1 text synchronization with the Android host via `xclip`.

---

## 3. Customization Guide

### 3.1 Hardware Acceleration (VirGL)

The environment automatically attempts to route OpenGL through the **Mali-G715 (Tensor G4)** GPU.
- **Driver:** `GALLIUM_DRIVER=virpipe`
- **Manual Toggle:** If performance is degraded, ensure `virgl_test_server` is active in the app settings.

### 3.2 High-Fidelity Audio (PipeWire)

PulseAudio has been replaced by **PipeWire** for low-latency, high-fidelity audio processing.
- **DSP Support:** Supports JamesDSP correction strings for mobile speaker calibration.
- **Bridge:** Audio is forwarded to the host via TCP port `4718`.

---

## 4. Neural Workflow Reference

### 4.1 The Intelligence Sink (`to_vault`)

Append neural text generation to your vault instantly:
```bash
# Example usage:
cat findings.txt | to_vault "Quantum_Research"
```
The function prepends ISO-8601 timestamps and frontmatter, saving the node to `~/Vault/Raw_Intel/`.

### 4.2 Rust-based Parsing Stack

Optimized utilities for manipulating large-scale intelligence data:
- `rg` (ripgrep): Instantaneous searching.
- `fd`: High-speed file discovery.
- `jq`: JSON processing for LLM responses.
- `fzf`: Fuzzy finding across your vault.

---

## 5. Troubleshooting Guide

### 5.1 Android 14 ptrace Denials

Android 14 blocks certain `ptrace` system calls used by PRoot. 
- **Fix:** DaRipped automatically exports `PROOT_NO_SECCOMP=1`. If the app crashes on launch, verify this variable in the "Startup Command" settings.

### 5.2 Display Sync Timeouts

If the app hangs at "Waiting for Termux:X11", the display socket (`X4`) was not created.
- **Fix:** Open the Termux:X11 app manually and ensure it is set to Display 4.

---

*Manual version: 2.1.0 · Updated: 2026-03-08*
