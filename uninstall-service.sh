#!/bin/bash

set -e

SERVICE_NAME="webm-converter"
SERVICE_FILE="webm-converter.service"
SYSTEMD_DIR="/etc/systemd/system"

echo "Uninstalling WebM Converter service..."

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

echo "Stopping service..."
systemctl stop $SERVICE_NAME 2>/dev/null || true

echo "Disabling service..."
systemctl disable $SERVICE_NAME 2>/dev/null || true

echo "Removing service file..."
rm -f "$SYSTEMD_DIR/$SERVICE_FILE"

echo "Reloading systemd daemon..."
systemctl daemon-reload

systemctl reset-failed 2>/dev/null || true

echo ""
echo "Service uninstalled successfully!"
echo ""
echo "The executable is still available at dist/webm-converter-linux"
echo "To run manually: ./dist/webm-converter-linux" 