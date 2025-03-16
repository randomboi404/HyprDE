#!/usr/bin/env bash

# Modify the configuration
sudo sed -i 's/^#HandlePowerKey=.*$/HandlePowerKey=ignore/' /etc/systemd/logind.conf

echo "Power button action has been set to 'ignore'."
