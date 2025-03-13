#!/bin/bash

# Wait until internet is available
until ping -c 1 www.google.com &> /dev/null; do
    sleep 60
done

# Check if already mounted
if ! mountpoint -q ~/MEGA; then
    sudo rclone mount mega: ~/MEGA \
        --vfs-cache-mode full \
        --vfs-cache-max-size 3G \
        --vfs-read-chunk-size 10M \
        --vfs-read-chunk-size-limit 100M \
        --buffer-size 0M \
        --allow-other \
        --daemon
fi
