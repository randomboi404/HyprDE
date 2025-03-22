#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status

# Check for GPU vendor
if lspci | grep -i "vga\|3d\|display" | grep -i "nvidia" &>/dev/null; then
    echo "NVIDIA GPU detected. Installing NVIDIA Vulkan packages..."
    if ! sudo pacman -S --noconfirm nvidia-utils lib32-nvidia-utils vulkan-icd-loader vulkan-tools; then
        echo "Error: Failed to install NVIDIA Vulkan support."
        exit 1
    fi
elif lspci | grep -i "vga\|3d\|display" | grep -i "amd\|ati" &>/dev/null; then
    echo "AMD GPU detected. Installing AMD Vulkan packages..."
    if ! sudo pacman -S --noconfirm vulkan-radeon lib32-vulkan-radeon vulkan-icd-loader vulkan-tools; then
        echo "Error: Failed to install AMD Vulkan support."
        exit 1
    fi
elif lspci | grep -i "vga\|3d\|display" | grep -i "intel" &>/dev/null; then
    echo "Intel GPU detected. Installing Intel Vulkan packages..."
    if ! sudo pacman -S --noconfirm vulkan-intel lib32-vulkan-intel vulkan-icd-loader vulkan-tools; then
        echo "Error: Failed to install Intel Vulkan support."
        exit 1
    fi
else
    echo "No specific GPU detected. Installing generic Vulkan support..."
    if ! sudo pacman -S --noconfirm vulkan-icd-loader vulkan-tools; then
        echo "Error: Failed to install generic Vulkan support."
        exit 1
    fi
fi

# Install common Vulkan development packages
echo "Installing common Vulkan development packages..."
if ! sudo pacman -S --noconfirm vulkan-headers vulkan-validation-layers; then
    echo "Error: Failed to install Vulkan development packages."
    exit 1
fi

echo "Vulkan support has been installed successfully."
