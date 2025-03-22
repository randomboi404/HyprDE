#!/usr/bin/env bash
#|---/ /+--------------------------------------+---/ /|#
#|--/ /-| Script to apply post install configs |--/ /-|#
#|-/ /--| Prasanth Rangan                      |-/ /--|#
#|/ /---+--------------------------------------+/ /---|#

scrDir=$(dirname "$(realpath "$0")")
# shellcheck disable=SC1091
if ! source "${scrDir}/global_fn.sh"; then
    echo "Error: unable to source global_fn.sh..."
    exit 1
fi

cloneDir="${cloneDir:-$CLONE_DIR}"

# sddm
if pkg_installed sddm; then
    print_log -c "[DISPLAYMANAGER] " -b "detected :: " "sddm"
    if [ ! -d /etc/sddm.conf.d ]; then
        sudo mkdir -p /etc/sddm.conf.d
    fi
    if [ ! -f /etc/sddm.conf.d/backup_the_hyde_project.conf ] || [ "${HYDE_INSTALL_SDDM}" = true ]; then
        print_log -g "[DISPLAYMANAGER] " -b " :: " "configuring sddm..."
        print_log -g "[DISPLAYMANAGER] " -b " :: " "Select sddm theme:" -r "\n[1]" -b " Candy" -r "\n[2]" -b " Corners"
        read -p " :: Enter option number : " -r sddmopt

        case $sddmopt in
        1) sddmtheme="Candy" ;;
        *) sddmtheme="Corners" ;;
        esac

        sudo tar -xzf "${cloneDir}/Source/arcs/Sddm_${sddmtheme}.tar.gz" -C /usr/share/sddm/themes/
        sudo touch /etc/sddm.conf.d/the_hyde_project.conf
        sudo cp /etc/sddm.conf.d/the_hyde_project.conf /etc/sddm.conf.d/backup_the_hyde_project.conf
        sudo cp /usr/share/sddm/themes/${sddmtheme}/the_hyde_project.conf /etc/sddm.conf.d/
    else
        print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is already configured..."
    fi

    if [ ! -f "/usr/share/sddm/faces/${USER}.face.icon" ] && [ -f "${cloneDir}/Source/misc/${USER}.face.icon" ]; then
        sudo cp "${cloneDir}/Source/misc/${USER}.face.icon" /usr/share/sddm/faces/
        print_log -g "[DISPLAYMANAGER] " -b " :: " "avatar set for ${USER}..."
    fi

else
    print_log -y "[DISPLAYMANAGER] " -b " :: " "sddm is not installed..."
fi

# dolphin
if pkg_installed dolphin && pkg_installed xdg-utils; then
    print_log -c "[FILEMANAGER] " -b "detected :: " "dolphin"
    xdg-mime default org.kde.dolphin.desktop inode/directory
    print_log -g "[FILEMANAGER] " -b " :: " "setting $(xdg-mime query default "inode/directory") as default file explorer..."

else
    print_log -y "[FILEMANAGER] " -b " :: " "dolphin is not installed..."
    print_log -y "[FILEMANAGER] " -b " :: " "Setting $(xdg-mime query default "inode/directory") as default file explorer..."
fi

# shell
"${scrDir}/restore_shl.sh"

# backup of /boot during pacman kernel updates
prompt_timer 60 "Automatically backup /boot for every kernel update? [Y/n]"
bootbkpopt=${PROMPT_INPUT,,}

if [ "${bootbkpopt}" = "y" ]; then
    print_log -g "[BOOT BACKUP]" -b "configure :: " "backup script"
    "${scrDir}/Misc Modules/boot_backup.sh"
fi

# power button behaviour
"${scrDir}/Misc Modules/change_pwr_btn_behaviour.sh"

# setup btrfs snapper
"${scrDir}/Misc Modules/setup_btrfs_snapper.sh"

# install thunar
prompt_timer 60 "Setup Thunar File Manager? (Dolphin already exists) [Y/n]"
bootbkpopt=${PROMPT_INPUT,,}

if [ "${bootbkpopt}" = "y" ]; then
    print_log -g "[THUNAR]" -b "install :: " "thunar file manager"
    sudo pacman -S --needed --noconfirm thunar gvfs gvfs-mtp gvfs-gphoto2 gvfs-afc gvfs-smb udisks2 polkit tumbler
fi

# setup gnome-keyring
sudo pacman -S --noconfirm gnome-keyring seahorse
systemctl --user enable gnome-keyring-daemon.service
systemctl --user start gnome-keyring-daemon.service

# sets up obs-cli for obs studio
if command -v obs &> /dev/null && command -v pipx &> /dev/null; then
    pipx install obs-cli
fi

# flatpak
if ! pkg_installed flatpak; then
    print_log -r "[FLATPAK]" -b "list :: " "flatpak application"
    awk -F '#' '$1 != "" {print "["++count"]", $1}' "${scrDir}/extra/custom_flat.lst"
    prompt_timer 60 "Install these flatpaks? [Y/n]"
    fpkopt=${PROMPT_INPUT,,}

    if [ "${fpkopt}" = "y" ]; then
        print_log -g "[FLATPAK]" -b "install :: " "flatpaks"
        "${scrDir}/extra/install_fpk.sh"
    else
        print_log -y "[FLATPAK]" -b "skip :: " "flatpak installation"
    fi

else
    print_log -y "[FLATPAK]" -b " :: " "flatpak is already installed"
fi

mkdir -p ~/Pictures/Wallpapers
cp "${scrDir}/Wallpapers/"* ~/Pictures/Wallpapers/
