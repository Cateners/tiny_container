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
sudo rm -rf "$ROOTFS"
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

    # Disable sandbox (Landlock/Seccomp not available inside nspawn container)
    sed -i "s/#DisableSandboxFilesystem/DisableSandboxFilesystem/" /etc/pacman.conf
    sed -i "s/#DisableSandboxSyscalls/DisableSandboxSyscalls/" /etc/pacman.conf
    # Also handle the generic DisableSandbox if present
    sed -i "s/#DisableSandbox/DisableSandbox/" /etc/pacman.conf

    # Create vconsole.conf to prevent mkinitcpio warning
    touch /etc/vconsole.conf

    # Full system update
    pacman -Syu --noconfirm --overwrite "*"
'


# Step 4: Install desktop environments (both installed; user picks one at first launch)
echo "[4/8] Installing desktop environments..."
sudo systemd-nspawn -D "$ROOTFS" --bind-ro=/etc/resolv.conf /bin/bash -c "
    pacman -S --noconfirm --overwrite '*' \
        xfce4 xfce4-goodies xfce4-terminal \
        lxqt openbox \
        tigervnc \
        python python-websockify python-numpy \
        firefox \
        noto-fonts noto-fonts-cjk ttf-dejavu \
        sudo base-devel git wget curl \
        bash-completion htop nano vim \
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
    
    # X session init — sources ~/.xinitrc which the app writes on first launch
    cat > /etc/X11/xinit/xinitrc << "XINITRC"
#!/bin/bash
exec bash ~/.xinitrc
XINITRC
    chmod +x /etc/X11/xinit/xinitrc
    
    # User xinitrc — XFCE4 as default; app overwrites this on first launch
    su - tiny -c "cat > ~/.xinitrc << EOF
#!/bin/bash
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE
exec startxfce4
EOF
chmod +x ~/.xinitrc"
    
    # VNC scripts
    cat > /usr/local/bin/start-vnc << "SCRIPT"
#!/bin/bash
export USER=tiny HOME=/home/tiny DISPLAY=:4
vncserver -kill :4 2>/dev/null || true
mkdir -p /home/tiny/.vnc
echo "12345678" | vncpasswd -f > /home/tiny/.vnc/passwd # Placeholder password, will be replaced by the app at runtime
chmod 600 /home/tiny/.vnc/passwd
chown -R tiny:tiny /home/tiny/.vnc
cat > /home/tiny/.vnc/xstartup << "XS"
#!/bin/bash
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
exec bash ~/.xinitrc
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
    # Backward-compat alias for any saved container configs using the old name
    ln -sf /usr/local/bin/start-desktop /usr/local/bin/startnovnc
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
