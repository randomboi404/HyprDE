#!/usr/bin/env sh

VIDEO_DIR="$HOME/Videos/OBS"
OBS_PORT=4455  # Define the WebSocket port

mkdir -p "$VIDEO_DIR"

# Function to check if OBS WebSocket is active
is_obs_websocket_active() {
    nc -z localhost $OBS_PORT >/dev/null 2>&1
    return $?
}

# Function to check if OBS Studio is running
is_obs_running() {
    pgrep -x obs >/dev/null 2>&1
    return $?
}

# Function to check if recording is active
is_obs_recording_active() {
    [ "$(obs-cli -P "$OBS_PORT" record status 2>/dev/null)" = "started" ]
    return $?
}

# Function to generate thumbnail at half the video duration
generate_thumbnail() {
    local video_file="$1"
    local thumb_file="/tmp/obs_recording_thumb.jpg"

    # Remove old thumbnail to force refresh
    rm -f "$thumb_file"

    # Get video duration using ffprobe (duration in seconds)
    duration=$(ffprobe -v error -select_streams v:0 -show_entries stream=duration \
              -of default=noprint_wrappers=1:nokey=1 "$video_file")
    # If duration not obtained, fallback to 2 seconds
    if [ -z "$duration" ]; then
        timestamp="2"
    else
        # Calculate half the duration using bc for floating point math
        timestamp=$(echo "$duration/2" | bc -l)
    fi

    # Generate new thumbnail using ffmpeg at the calculated timestamp
    ffmpeg -ss "$timestamp" -i "$video_file" -vframes 1 -q:v 3 "$thumb_file" -y >/dev/null 2>&1

    echo "$thumb_file"
}

case "$1" in
    r) # Start recording
        # Check if OBS is running
        if ! is_obs_running; then
            notify-send -a "OBS Recording" "OBS Studio is not running. Start OBS before recording."
            exit 1
        fi

        # Check if OBS WebSocket is active
        if ! is_obs_websocket_active; then
            notify-send -a "OBS Recording" "OBS WebSocket is not active on port $OBS_PORT. Ensure OBS is configured for remote control."
            exit 1
        fi

        # Check if recording is already in progress
        if is_obs_recording_active; then
            notify-send -a "OBS Recording" "Recording is already in progress!"
            exit 1
        fi

        # Start recording
        obs-cli -P "$OBS_PORT" record start
        notify-send "OBS Recording" "Recording started."
        ;;
    s) # Stop recording
        # Check if recording is actually in progress
        if ! is_obs_recording_active; then
            exit 0  # Exit silently if not recording
        fi

        # Stop recording
        obs-cli -P "$OBS_PORT" record stop

        # Wait a bit to ensure OBS saves the file
        sleep 3

        # Get the latest recorded file
        LAST_FILE=$(ls -t "$VIDEO_DIR"/*.mkv "$VIDEO_DIR"/*.mp4 2>/dev/null | head -n1)

        if [ -n "$LAST_FILE" ]; then
            THUMBNAIL=$(generate_thumbnail "$LAST_FILE")
            notify-send -a "OBS Recording" -i "$THUMBNAIL" "Recording Stopped" "Saved as $(basename "$LAST_FILE")"
        else
            notify-send -a "OBS Recording" -i "video-display" "Recording Stopped" "Recording has been saved."
        fi
        ;;
    a) # Toggle recording: start if not recording; stop if recording.
        # Check if OBS is running
        if ! is_obs_running; then
            notify-send -a "OBS Recording" "OBS Studio is not running. Start OBS before recording."
            exit 1
        fi

        # Check if OBS WebSocket is active
        if ! is_obs_websocket_active; then
            notify-send -a "OBS Recording" "OBS WebSocket is not active on port $OBS_PORT. Ensure OBS is configured for remote control."
            exit 1
        fi

        if is_obs_recording_active; then
            # Stop recording
            obs-cli -P "$OBS_PORT" record stop

            # Wait a bit to ensure OBS saves the file
            sleep 3

            # Get the latest recorded file
            LAST_FILE=$(ls -t "$VIDEO_DIR"/*.mkv "$VIDEO_DIR"/*.mp4 2>/dev/null | head -n1)

            if [ -n "$LAST_FILE" ]; then
                THUMBNAIL=$(generate_thumbnail "$LAST_FILE")
                notify-send -a "OBS Recording" -i "$THUMBNAIL" "Recording Stopped" "Saved as $(basename "$LAST_FILE")"
            else
                notify-send -a "OBS Recording" -i "video-display" "Recording Stopped" "Recording has been saved."
            fi
        else
            # Start recording
            obs-cli -P "$OBS_PORT" record start
            notify-send "OBS Recording" "Recording started."
        fi
        ;;
    *)
        echo "Usage: $0 <r|s|a>"
        echo "    r  : Start recording"
        echo "    s  : Stop recording (includes thumbnail in notification)"
        echo "    a  : Toggle recording (start if not recording; stop if recording)"
        exit 1
        ;;
esac
