#!/usr/bin/env sh

current_workspace=$(hyprctl activeworkspace -j | jq -r '.id')
previous_workspace=$(cat ~/.cache/workspace/previous_workspace)

change_workspace() {
    if [ "$current_workspace" != "$2" ]; then
        hyprctl dispatch workspace "$2"
    else
        if [ "$current_workspace" != "$previous_workspace" ]; then
            hyprctl dispatch workspace "$previous_workspace"
        fi
    fi
}

change_workspace_previous() {
    if [ "$current_workspace" != "$previous_workspace" ]; then
        hyprctl dispatch workspace "$previous_workspace"
    fi
}

switch_to_relative_workspace_right() {
    hyprctl dispatch workspace r+1
}

switch_to_relative_workspace_left() {
    hyprctl dispatch workspace r-1
}

switch_to_relative_active_workspace_right() {
    hyprctl dispatch workspace e+1
}

switch_to_relative_active_workspace_left() {
    hyprctl dispatch workspace e-1
}

shift_to_first_empty_workspace() {
    hyprctl dispatch workspace empty
}

shift_to_workspace() {
    hyprctl dispatch movetoworkspace "$2"
}

case "$1" in
    cw)
        change_workspace "$@"
        ;;
    cwp)
        change_workspace_previous "$@"
        ;;
    srwr)
        switch_to_relative_workspace_right "$@"
        ;;
    srwl)
        switch_to_relative_workspace_left "$@"
        ;;
    srawr)
        switch_to_relative_active_workspace_right "$@"
        ;;
    srawl)
        switch_to_relative_active_workspace_left "$@"
        ;;
    sfew)
        shift_to_first_empty_workspace
        ;;
    sw)
        shift_to_workspace "$@"
        ;;
    *)
        echo "Usage: $0 {cw|cwp|srwr|srwl|srawr|srawl|sfew|sw} <workspace>"
        exit 1
        ;;
esac
