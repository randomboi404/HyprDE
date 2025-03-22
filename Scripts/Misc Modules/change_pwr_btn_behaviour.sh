#!/usr/bin/env bash

set -e  # Exit immediately if a command exits with a non-zero status
# Modify the configuration
sudo sed -i 's/^#HandlePowerKey=.*$/HandlePowerKey=ignore/' /etc/systemd/logind.conf

echo "Power button action has been set to 'ignore'."
