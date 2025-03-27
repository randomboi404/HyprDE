#!/bin/bash

battery_during_msg=0

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

    if [ "$battery_percentage" -eq 50 ]; then
        notify-send "Half Headphone Battery" "Headphones battery is currently at 50%."
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
