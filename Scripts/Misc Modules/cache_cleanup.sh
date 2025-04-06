#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status
sudo -v  # Prompt for sudo password

# Get the username of the person running the script (not root)
USERNAME=$(logname)
USER_HOME=$(eval echo "~$USERNAME")

sudo tee /etc/systemd/system/aur-pacman-cache-cleanup.service >/dev/null <<EOF
[Unit]
Description=Clean Pacman, Paru, and Yay caches older than 30 days

[Service]
Type=oneshot
SuccessExitStatus=0 1
ExecStart=/bin/bash -c '/usr/bin/paccache --remove --min-atime "30 days ago"; \
  [ -d "$USER_HOME/paru" ] && find "$USER_HOME/paru" -type f -mtime +30 -delete; \
  [ -d "$USER_HOME/yay" ] && find "$USER_HOME/yay" -type f -mtime +30 -delete'
EOF

sudo tee /etc/systemd/system/aur-pacman-cache-cleanup.timer >/dev/null <<'EOF'
[Unit]
Description=Weekly cache clean for Pacman and AUR

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now aur-pacman-cache-cleanup.timer