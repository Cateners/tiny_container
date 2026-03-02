# Building the Arch Linux ARM Rootfs

This document outlines the manual process for creating the `archlinux.tar.xz` rootfs that is bundled with the application. The automated version of this process is available in the `build-arch-rootfs.sh` script.

## Prerequisites

-   A host machine running a modern Linux distribution. An Arch-based distro (like CachyOS or vanilla Arch) is recommended as it has `systemd-nspawn` readily available.
-   `sudo` or root access on the build machine.
-   Required packages: `wget`, `tar`, `systemd-nspawn`.
-   If your host machine is not `aarch64`, you will also need `qemu-user-static` and `binfmt-support` to run the ARM-based environment.

## Build Procedure

### 1. Download and Extract the Base Rootfs

First, download the latest generic Arch Linux ARM rootfs for the `aarch64` architecture.

```bash
# Create a working directory
mkdir -p archroot-build/rootfs
cd archroot-build

# Download the rootfs tarball
wget http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz

# Extract the tarball into the rootfs directory as root
sudo tar -xzf ArchLinuxARM-aarch64-latest.tar.gz -C rootfs/
```

### 2. Configure the System via `systemd-nspawn`

`systemd-nspawn` allows you to enter the new rootfs as if it were a container, using your host's kernel.

```bash
# Enter the container. We bind the host's DNS settings to ensure network access.
sudo systemd-nspawn -D "$(pwd)/rootfs" --bind-ro=/etc/resolv.conf /bin/bash
```

### 3. Inside the Container: System Initialization

Once you are inside the container's shell, you need to initialize the `pacman` keyring and update the system.

```bash
# Initialize pacman's keyring
pacman-key --init
pacman-key --populate archlinuxarm

# Enable parallel downloads for faster package installation
sed -i 's/#ParallelDownloads = 5/ParallelDownloads = 5/' /etc/pacman.conf

# Perform a full system upgrade
pacman -Syu --noconfirm
```

### 4. Inside the Container: Install Packages

Install the desktop environment (XFCE), VNC server, and other necessary utilities.

```bash
pacman -S --noconfirm \
    xfce4 xfce4-goodies xfce4-terminal \
    tigervnc \
    novnc \
    python python-websockify python-numpy \
    firefox \
    noto-fonts noto-fonts-cjk ttf-dejavu \
    sudo base-devel git wget curl \
    bash-completion htop neofetch nano vim \
    xdg-utils xdg-user-dirs dbus \
    xorg-server xorg-xinit xorg-xauth
```

### 5. Inside the Container: User and Locale Setup

Create the default `tiny` user and configure the system locale.

```bash
# Create the 'tiny' user, add them to the 'wheel' group for sudo access
useradd -m -G wheel -s /bin/bash tiny
echo "tiny:tiny" | chpasswd

# Configure sudo to allow the 'wheel' group to execute commands without a password
echo "%wheel ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/wheel
chmod 440 /etc/sudoers.d/wheel

# Generate the en_US.UTF-8 locale
sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
```

### 6. Inside the Container: Cleanup

Before packaging the rootfs, clean up package caches and temporary files to reduce the final size.

```bash
pacman -Scc --noconfirm
rm -rf /var/cache/pacman/pkg/*
rm -rf /tmp/*
rm -f /root/.bash_history
# Exit the container shell
exit
```

### 7. Package the Rootfs

Now, back on your host machine, create the final compressed tarball.

```bash
# Navigate into the rootfs directory
cd rootfs/

# Create the tarball, excluding pseudo-filesystems
sudo tar -Jcpf ../archlinux.tar.xz \
    --exclude=./dev \
    --exclude=./proc \
    --exclude=./sys \
    --exclude=./archlinux.tar.xz .

cd ..
```

### 8. Split the Tarball for APK Bundling

The Android build system has a limit on asset file sizes. Split the large tarball into 98MB chunks.

```bash
split -b 98M archlinux.tar.xz
```

This will produce files named `xaa`, `xab`, etc. These are the files you need to copy into the `assets/` directory of the Flutter project before building the APK.

