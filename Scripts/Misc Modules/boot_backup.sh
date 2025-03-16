#!/usr/bin/env bash

# Create pacman hooks directory
sudo mkdir -p /etc/pacman.d/hooks

# Create the pre-transaction hook
sudo tee /etc/pacman.d/hooks/55-bootbackup_pre.hook >/dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up pre /boot...
When = PreTransaction
Exec = /usr/bin/bash -c 'rsync -a --mkpath --delete /boot/ "/.bootbackup/$(date +%Y_%m_%d_%H.%M.%S)_pre"/'
EOF

# Create the post-transaction hook
sudo tee /etc/pacman.d/hooks/95-bootbackup_post.hook >/dev/null <<'EOF'
[Trigger]
Operation = Upgrade
Operation = Install
Operation = Remove
Type = Path
Target = usr/lib/modules/*/vmlinuz

[Action]
Depends = rsync
Description = Backing up post /boot...
When = PostTransaction
Exec = /usr/bin/bash -c 'rsync -a --mkpath --delete /boot/ "/.bootbackup/$(date +%Y_%m_%d_%H.%M.%S)_post"/'
EOF

# Create the cleanup script
sudo tee /usr/local/bin/clean_boot_backups.sh >/dev/null <<'EOF'
#!/bin/bash
# Define backup directory
BACKUP_DIR="/.bootbackup"

# Remove backups older than 7 days
find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \;

# Optional: Log cleanup (uncomment to enable)
# echo "$(date): Cleaned up old boot backups" >> /var/log/bootbackup_cleanup.log
EOF
sudo chmod +x /usr/local/bin/clean_boot_backups.sh

# Create systemd service for cleanup
sudo tee /etc/systemd/system/boot-backup-cleanup.service >/dev/null <<'EOF'
[Unit]
Description=Cleanup old /boot backups
After=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/clean_boot_backups.sh
EOF

# Create systemd timer for daily cleanup
sudo tee /etc/systemd/system/boot-backup-cleanup.timer >/dev/null <<'EOF'
[Unit]
Description=Run /boot backup cleanup daily

[Timer]
OnCalendar=daily
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd daemon and enable the timer
sudo systemctl daemon-reload
sudo systemctl enable --now boot-backup-cleanup.timer

# Update PRUNENAMES in updatedb.conf
echo 'PRUNENAMES = ".snapshots"' | sudo tee /etc/updatedb.conf >/dev/null
