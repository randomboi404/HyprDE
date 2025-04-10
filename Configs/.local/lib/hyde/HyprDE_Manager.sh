#!/bin/bash
# HyprDE Manager Script - A unified UI for system update, backup, dotfiles, and maintenance.
# This script uses yad for a graphical interface and pkexec for privileged operations.
# Strict mode: exit on errors, undefined variables, and pipeline errors.
set -euo pipefail

# Define configuration paths
HYPR_CONFIG_DIR="$HOME/.config/hypr"
MAIN_CONFIG_FILE="$HYPR_CONFIG_DIR/hypr.conf"
KEYBINDINGS_FILE="$HYPR_CONFIG_DIR/keybindings.conf"
AUTOSTART_FILE="$HYPR_CONFIG_DIR/autostart.conf"
STARTUP_DIR="$HYPR_CONFIG_DIR/startup"
BOOT_BACKUP_DIR="/.bootbackup"

# Function to display informational messages using YAD
show_info() {
  local message="$1"
  notify-send "HyprDE Manager" "$message"
}

# Function to execute commands in a terminal using hyprctl
execute_command() {
  local cmd="$1"
  hyprctl dispatch exec "kitty --hold $cmd"
}

# Update system based on passed option
update_system() {
  local update_type="$1"
  case "$update_type" in
    full)
      hyprctl dispatch exec "systemupdate.sh up"
      show_info "Executing full system update..."
      exit 0
      ;;
    pacman)
      execute_command "clear && fastfetch && sudo pacman -Syu"
      show_info "Executing pacman update..."
      exit 0
      ;;
    aur)
      if command -v paru &>/dev/null; then
        execute_command "paru -Syu --aur"
        show_info "Executing AUR update with paru..."
        exit 0
      elif command -v yay &>/dev/null; then
        execute_command "yay -Syu --aur"
        show_info "Executing AUR update with yay..."
        exit 0
      else
        show_info "Neither paru nor yay is installed. Please install one to update AUR packages."
        return
      fi
      ;;
    flatpak)
      if ! command -v flatpak &>/dev/null; then
        show_info "Flatpak is not installed."
        return
      fi
      execute_command "flatpak update"
      ;;
    *)
      show_info "Unknown update option: $update_type"
      return
      ;;
  esac
  return 0
}

# Backup system: BTRFS snapshot and/or boot directory backup
backup_system() {
  local backup_type="$1"
  case "$backup_type" in
    btrfs)
      if ! command -v snapper &>/dev/null; then
        show_info "Snapper is not installed. Please install it to create BTRFS snapshots."
        return
      fi
      for cfg in root home; do
        if [ ! -e "/etc/snapper/configs/$cfg" ]; then
          show_info "Snapper configuration for ${cfg} is missing. Please create it first."
          return
        fi
      done

      if ! pkexec bash -c '
        snapper -c root create --description "Manual Snapshot" && \
        snapper -c home create --description "Manual Snapshot"
      '; then
        show_info "Could not create BTRFS snapshot. Operation cancelled or authorization failed."
        return
      fi
      show_info "BTRFS snapshots created successfully."
      ;;
    
    boot)
      local backup_dir="$BOOT_BACKUP_DIR/$(date +%Y_%m_%d_%H.%M.%S)"
      if ! pkexec rsync -a --mkpath --delete /boot/ "$backup_dir/"; then
        show_info "Could not backup /boot directory. Operation cancelled or authorization failed."
        return
      fi
      show_info "Backup of /boot directory created successfully at $backup_dir."
      ;;
    
    full)
      backup_system btrfs
      backup_system boot
      ;;
    
    *)
      show_info "Unknown backup option: $backup_type"
      return
      ;;
  esac
  return 0
}

# Manage dotfiles and related configurations using xdg-open
manage_dotfiles() {
  local target="$1"
  local file_to_open=""
  case "$target" in
    main)
      file_to_open="$MAIN_CONFIG_FILE"
      ;;
    keybindings)
      file_to_open="$KEYBINDINGS_FILE"
      ;;
    autostart)
      file_to_open="$AUTOSTART_FILE"
      ;;
    startup)
      file_to_open="$STARTUP_DIR"
      ;;
    *)
      show_info "Unknown dotfiles target: $target"
      return
      ;;
  esac

  if [ ! -e "$file_to_open" ]; then
    show_info "The target ($file_to_open) does not exist."
    return
  fi

  hyprctl dispatch exec xdg-open $file_to_open
  exit 0
}

# Clear package manager caches using elevated privileges
maintain_system() {
  local cache_type="$1"
  case "$cache_type" in
    pacman)
      if ! pkexec pacman -Scc --noconfirm; then
        show_info "Could not clear pacman cache. Operation cancelled or authorization failed."
        return
      fi
      show_info "Pacman cache cleared."
      ;;
    
    aur)
      if command -v paru &>/dev/null; then
        if ! pkexec paru -Sc --noconfirm; then
          show_info "Could not clear paru cache. Operation cancelled or authorization failed."
          return
        fi
        show_info "Paru cache cleared."
      elif command -v yay &>/dev/null; then
        if ! pkexec yay -Sc --noconfirm; then
          show_info "Could not clear yay cache. Operation cancelled or authorization failed."
          return
        fi
        show_info "Yay cache cleared."
      else
        show_info "Neither paru nor yay is installed."
        return
      fi
      ;;
    
    flatpak)
      if ! command -v flatpak &>/dev/null; then
        show_info "Flatpak is not installed."
        return
      fi
      if ! pkexec flatpak uninstall --unused -y; then
        show_info "Could not clear flatpak cache. Operation cancelled or authorization failed."
        return
      fi
      show_info "Flatpak cache cleared."
      ;;
    
    all)
      maintain_system pacman
      maintain_system aur
      maintain_system flatpak
      ;;
    
    *)
      show_info "Unknown system maintenance option: $cache_type"
      return
      ;;
  esac
  return 0
}

# Main loop using YAD for the graphical interface
while true; do
  selection=$(yad --list \
    --title="HyprDE Manager" \
    --width=600 --height=400 \
    --center \
    --column="Task" --column="Description" \
    "Update" "Install system updates" \
    "Backup" "Create snapshots and backup /boot" \
    "Dotfiles" "Manage dotfiles" \
    "System Maintenance" "Maintain the system" \
    --button=Cancel:1 --button=Select:0)

  # Exit main loop if Cancel pressed or no selection made
  if [[ $? -ne 0 || -z "$selection" ]]; then
    break
  fi

  choice=$(echo "$selection" | cut -d"|" -f1)
  case "$choice" in
    Update)
      if ! sub_selection=$(yad --list \
        --title="Update Options" \
        --width=500 --height=300 \
        --center \
        --column="Option" --column="Description" \
        "Full Update" "Run full system update" \
        "Pacman Update" "Run pacman update" \
        "AUR Update" "Update AUR packages" \
        "Flatpak Update" "Update flatpak packages" \
        --button=Back:1 --button=Select:0); then
        continue
      fi

      sub_choice=$(echo "$sub_selection" | cut -d"|" -f1)
      case "$sub_choice" in
        "Full Update")
          update_system full
          show_info "Executing full system update..."
          ;;
        "Pacman Update")
          update_system pacman
          show_info "Executing pacman update..."
          ;;
        "AUR Update")
          update_system aur
          ;;
        "Flatpak Update")
          show_info "Executing flatpak update..."
          update_system flatpak
          ;;
      esac
      ;;
    
    Backup)
      if ! sub_selection=$(yad --list \
        --title="Backup Options" \
        --width=500 --height=300 \
        --center \
        --column="Option" --column="Description" \
        "BTRFS Snapshot" "Create BTRFS snapshots for root and home" \
        "Boot Backup" "Backup /boot directory" \
        "Full Backup" "Create snapshots and backup /boot" \
        --button=Back:1 --button=Select:0); then
        continue
      fi

      sub_choice=$(echo "$sub_selection" | cut -d"|" -f1)
      case "$sub_choice" in
        "BTRFS Snapshot")
          backup_system btrfs
          ;;
        "Boot Backup")
          backup_system boot
          ;;
        "Full Backup")
          backup_system full
          ;;
      esac
      ;;
    
    Dotfiles)
      if ! sub_selection=$(yad --list \
        --title="Dotfiles Options" \
        --width=500 --height=300 \
        --center \
        --column="Option" --column="Description" \
        "Main Conf" "Manage main configuration file" \
        "Keybindings" "Manage keybindings configuration file" \
        "Autostart" "Manage autostart configuration file" \
        "Startup" "Manage startup folder" \
        --button=Back:1 --button=Select:0); then
        continue
      fi

      sub_choice=$(echo "$sub_selection" | cut -d"|" -f1)
      case "$sub_choice" in
        "Main Conf")
          manage_dotfiles main
          ;;
        "Keybindings")
          manage_dotfiles keybindings
          ;;
        "Autostart")
          manage_dotfiles autostart
          ;;
        "Startup")
          manage_dotfiles startup
          ;;
      esac
      ;;
    
    "System Maintenance")
      if ! sub_selection=$(yad --list \
        --title="System Maintenance Options" \
        --width=500 --height=300 \
        --center \
        --column="Option" --column="Description" \
        "Clear Pacman Cache" "Clear the pacman cache" \
        "Clear AUR Cache" "Clear the AUR cache" \
        "Clear Flatpak Cache" "Clear the flatpak cache" \
        "Clear Entire Cache" "Clear pacman, AUR, and flatpak caches" \
        --button=Back:1 --button=Select:0); then
        continue
      fi

      sub_choice=$(echo "$sub_selection" | cut -d"|" -f1)
      case "$sub_choice" in
        "Clear Pacman Cache")
          maintain_system pacman
          ;;
        "Clear AUR Cache")
          maintain_system aur
          ;;
        "Clear Flatpak Cache")
          maintain_system flatpak
          ;;
        "Clear Entire Cache")
          maintain_system all
          ;;
      esac
      ;;
  esac
done
