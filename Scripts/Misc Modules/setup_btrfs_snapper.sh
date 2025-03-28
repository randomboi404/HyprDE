#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

# Default subvolume names used in many BTRFS snapshot setups.
ROOT_SUBVOL="@"
HOME_SUBVOL="@home"

# Check if the root filesystem is BTRFS
if ! sudo findmnt -t btrfs -n / >/dev/null 2>&1; then
    echo "The root filesystem is not BTRFS. Exiting."
    exit 0
fi

# Get the list of subvolumes from the root
subvol_list=$(sudo btrfs subvolume list / 2>/dev/null)

# Check for the expected root subvolume (e.g., '@')
if ! echo "$subvol_list" | grep -q "path $ROOT_SUBVOL\$"; then
    echo "Error: Subvolume '$ROOT_SUBVOL' not found on the root filesystem."
    echo "Exiting without configuring snapper."
    exit 0
else
    echo "Found root subvolume '$ROOT_SUBVOL'."
    create_root_config=true
fi

# Check for the expected home subvolume (e.g., '@home')
if echo "$subvol_list" | grep -q "path $HOME_SUBVOL\$"; then
    echo "Found home subvolume '$HOME_SUBVOL'."
    create_home_config=true
else
    echo "Warning: Subvolume '$HOME_SUBVOL' not found on the root filesystem."
    echo "The system will continue without BTRFS snapshots for the home directory."
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
if [ "$create_root_config" = true ] && [ ! -f /etc/snapper/configs/root ]; then
    echo "Creating snapper configuration for /..."
    sudo snapper -c root create-config /
fi

# Create snapper configuration for "/home" if it does not exist
if [ "$create_home_config" = true ] && [ ! -f /etc/snapper/configs/home ]; then
    echo "Creating snapper configuration for /home..."
    sudo snapper -c home create-config /home
fi

echo "BTRFS Snapper setup completed successfully!"
echo "Make sure to setup other subvolumes as well if any."
