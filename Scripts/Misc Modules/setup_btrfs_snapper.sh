#!/usr/bin/env bash

# Check if the root filesystem is BTRFS
fstype=$(findmnt -n -o FSTYPE /)
if [ "$fstype" != "btrfs" ]; then
    echo "Error: Filesystem is not BTRFS, hence snapper cannot be configured."
    echo "This is not an error - the system will continue without BTRFS snapshots."
    exit 0
fi

# Check for "root" and "home" subvolumes
if ! btrfs subvolume list / 2>/dev/null | grep -q "path root\$"; then
    echo "Error: 'root' subvolume not found."
    echo "This is not an error - the system will continue without BTRFS snapshots."
    exit 0
fi

if ! btrfs subvolume list / 2>/dev/null | grep -q "path home\$"; then
    echo "Error: 'home' subvolume not found."
    echo "This is not an error - the system will continue without BTRFS snapshots."
    exit 0
fi

# Detect available AUR helper: prefer paru over yay
if command -v paru &>/dev/null; then
    AUR_HELPER="paru"
elif command -v yay &>/dev/null; then
    AUR_HELPER="yay"
else
    echo "No AUR Helper found."
    echo "This is not an error - the system will continue without BTRFS snapshots."
    exit 0
fi

echo "Using $AUR_HELPER to install required packages..."
$AUR_HELPER -S --noconfirm btrfs-assistant snapper snap-pac grub-btrfs

# Modify mkinitcpio.conf to enable OverlayFS support (adding grub-btrfs-overlayfs hook)
echo "Modifying /etc/mkinitcpio.conf to add grub-btrfs-overlayfs hook..."
sudo sed -i 's/^HOOKS=(.*)$/HOOKS=(base udev autodetect microcode modconf kms keyboard keymap consolefont block filesystems fsck grub-btrfs-overlayfs)/' /etc/mkinitcpio.conf

# Regenerate initramfs
echo "Regenerating initramfs..."
sudo mkinitcpio -P

# Enable grub-btrfs service
echo "Enabling grub-btrfsd.service..."
sudo systemctl enable --now grub-btrfsd.service

# Create snapper configuration for "/" if it does not exist
if [ ! -f /etc/snapper/configs/root ]; then
    echo "Creating snapper configuration for /..."
    sudo snapper -c root create-config /
fi

echo "BTRFS Snapper setup completed successfully!"
