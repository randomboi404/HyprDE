#!/usr/bin/env bash

# Startup Check (Remove below chunk if running manually)
if [ "$(date +%u)" -ne 7 ]; then # Runs check every Sunday only (1 time per week)
    exit 0
fi

# Max allowed entries
MAX_ENTRIES=3000

# Count current cliphist entries
current_count=$(cliphist list | wc -l)

# Check and delete oldest items if over limit
if [ "$current_count" -gt "$MAX_ENTRIES" ]; then
    echo "[clipboard-trim] Clipboard count: $current_count — trimming..."

    # Calculate how many to delete
    delete_count=$((current_count - MAX_ENTRIES))

    # Get the oldest entries and delete them
    cliphist list | tail -n "$delete_count" | while read -r item; do
        [ -n "$item" ] && echo "$item" | cliphist delete
    done
else
    echo "[clipboard-trim] Clipboard count OK: $current_count"
fi
