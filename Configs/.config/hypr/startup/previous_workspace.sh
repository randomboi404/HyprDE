#!/bin/bash

# This script periodically checks the active workspace in Hyprland and logs any changes,
# saving the previous workspace to a designated file.

# Path to the file where the previous workspace will be saved.
OUTPUT_FILE="$HOME/.cache/workspace/previous_workspace"

# Interval in seconds between checks.
INTERVAL=0.2

mkdir -p ~/.cache/workspace

# Function to get the current active workspace.
get_active_workspace() {
    hyprctl monitors | awk '/active workspace/ {print $3}'
}

# Initialize previous and current workspace variables.
prev_workspace=""
current_workspace=$(get_active_workspace)

# Main loop to monitor workspace changes.
while true; do
    # Update previous workspace.
    prev_workspace=$current_workspace

    # Get the current active workspace.
    current_workspace=$(get_active_workspace)

    # If the workspace has changed, log the previous workspace.
    if [ "$current_workspace" != "$prev_workspace" ]; then
        echo "$prev_workspace" > "$OUTPUT_FILE"
    fi

    # Wait for the specified interval before checking again.
    sleep $INTERVAL
done
