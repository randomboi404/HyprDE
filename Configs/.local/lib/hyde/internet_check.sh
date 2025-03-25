#!/usr/bin/env sh

if ! nmcli -t -f DEVICE,STATE dev | grep -q ":connected$"; then
    icon=""
    tooltip="No Network Connected"
else
    if ping -q -c 1 8.8.8.8 >/dev/null; then
        icon=" "
        tooltip="Connected with Internet"
    else
        icon=" "
        tooltip="Connected but no Internet"
    fi
fi

echo "{\"text\": \"$icon\", \"tooltip\": \"$tooltip\"}"
