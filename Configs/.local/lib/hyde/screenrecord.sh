#!/usr/bin/env sh

# Directory to save recordings
VIDEO_DIR="$HOME/Videos/Recordings"

# Ensure the save directory exists
mkdir -p "$VIDEO_DIR"

# Function to get the display's resolution
get_display_resolution() {
    xrandr | grep '*' | awk '{print $1}'
}

# Function to get the display's refresh rate (fps)
get_display_fps() {
    # Extracts the integer portion of the FPS.
    xrandr | grep '*' | awk '{print $2}' | cut -d'.' -f1
}

# Function to get the system audio source (the monitor of the default sink)
# This ensures only system audio is captured, not surroundings.
get_system_audio_source() {
    default_sink=$(pactl get-default-sink)
    # Append .monitor to capture the output (system audio) of the default sink.
    echo "${default_sink}.monitor"
}

# Function to start recording
start_recording() {
    local resolution=$(get_display_resolution)
    local fps=$(get_display_fps)
    local audio_source=$(get_system_audio_source)
    local output_file="$VIDEO_DIR/recording_$(date +%Y%m%d_%H%M%S).mp4"

    # Start recording using gpu-screen-recorder with proper video and audio options.
    # The command captures the full screen ("-w screen"), using the detected resolution and FPS or activates portal without 'fs' argument ("-w portal").
    # It now also captures system audio via the monitor of the default sink ("-a $audio_source").
    echo "Second argument: '$1'"
    if [ "$1" = "fs" ]; then
        gpu-screen-recorder -w screen -s "$resolution" -f "$fps" -a "$audio_source" -o "$output_file" &
        notify-send "Screen Recording" "Recording started at $resolution and ${fps} FPS."
    else
        gpu-screen-recorder -w portal -s "$resolution" -f "$fps" -a "$audio_source" -o "$output_file" &
    fi
    echo $! > /tmp/screenrecord_pid
    
}

# Function to stop recording
stop_recording() {
    if [ -f /tmp/screenrecord_pid ]; then
        # Use kill with the correct signal (without the SIG prefix)
        kill -INT $(cat /tmp/screenrecord_pid)
        rm /tmp/screenrecord_pid
        notify-send "Screen Recording" "Recording stopped and saved."
    else
        notify-send "Screen Recording" "No active recording found."
    fi
}

case "$1" in
    r) # Start recording
        start_recording "$2"
        ;;
    s) # Stop recording
        stop_recording
        ;;
    a) # Toggle recording: if recording is active, stop it; otherwise, start recording.
        if [ -f /tmp/screenrecord_pid ]; then
            pid=$(cat /tmp/screenrecord_pid)
            if kill -0 "$pid" 2>/dev/null; then
                stop_recording
            else
                rm /tmp/screenrecord_pid
                start_recording "$2"
            fi
        else
            start_recording "$2"
        fi
        ;;
    *)
        echo "Usage: $0 <r|s|a>"
        echo "    r       : Start fullscreen recording"
        echo "    s       : Stop recording"
        echo "    a       : Toggle recording (start if not recording; stop if recording)"
        echo "    \$1 fs   : Starts recording with fullscreen without activating portal (optional; to be used with 'r' or 'a')"
        exit 1
        ;;
esac
