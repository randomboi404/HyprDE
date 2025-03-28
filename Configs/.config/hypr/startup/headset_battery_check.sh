#!/bin/bash

battery_during_msg=0
notified_50=0

check_battery() {
    # Gets info about headset from upower output
    device_path=$(upower -e | grep -i headset | head -1)

    if [ -z "$device_path" ]; then
        return
    fi

    # Retrieve battery percentage (removes the '%' sign)
    battery_percentage=$(upower -i "$device_path" 2>/dev/null | grep -E "percentage" | awk '{print $2}' | tr -d '%')

    # Check if battery information was retrieved
    if [ -z "$battery_percentage" ]; then
        return
    fi

    # Send 50% notification only once
    if [ "$battery_percentage" -eq 50 ] && [ "$notified_50" -eq 0 ]; then
        notify-send "Half Headphone Battery" "Headphones battery is currently at 50%."
        notified_50=1
    fi

    # Reset the 50% notification flag if battery goes above 50%
    if [ "$battery_percentage" -gt 50 ]; then
        notified_50=0
    fi

    # Compare the battery percentage with threshold (30%)
    if [ "$battery_percentage" -le 30 ]; then
        if [ "$battery_percentage" -eq "$battery_during_msg" ]; then
            return
        fi
        notify-send "Low Headphones Battery" "Headphones battery is currently at $battery_percentage%."
        battery_during_msg=$battery_percentage
    fi
}

# Run the check every three minutes
while true; do
    check_battery
    sleep 180
done
