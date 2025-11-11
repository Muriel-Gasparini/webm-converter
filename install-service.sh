#!/bin/bash

set -e

SERVICE_NAME="webm-converter"
SERVICE_FILE="webm-converter.service"
SYSTEMD_DIR="/etc/systemd/system"
CURRENT_DIR="$(pwd)"

echo "Installing WebM Converter as systemd service..."

if [ "$EUID" -ne 0 ]; then
    echo "This script must be run as root (use sudo)"
    exit 1
fi

if [ -n "$1" ]; then
    TARGET_USER="$1"
else
    TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo $USER)}"
fi

TARGET_GROUP="$(id -gn $TARGET_USER 2>/dev/null || echo $TARGET_USER)"
HOME_DIR="$(eval echo ~$TARGET_USER)"
WORKING_DIR="$CURRENT_DIR"
EXEC_PATH="$CURRENT_DIR/dist/webm-converter-linux"
WATCH_DIR="$HOME_DIR/Videos/Screencasts"

echo "Detected configuration:"
echo "  User: $TARGET_USER"
echo "  Group: $TARGET_GROUP"
echo "  Home: $HOME_DIR"
echo "  Working directory: $WORKING_DIR"
echo "  Executable: $EXEC_PATH"
echo "  Monitored directory: $WATCH_DIR"
echo ""

if [ ! -f "dist/webm-converter-linux" ]; then
    echo "Executable not found at dist/webm-converter-linux"
    echo "Run 'yarn build:linux' first"
    exit 1
fi

if [ ! -f "dist/icon.png" ]; then
    echo "Icon not found at dist/icon.png"
    echo "Run 'yarn build:linux' first to include the icon"
fi

if [ ! -f "$SERVICE_FILE" ]; then
    echo "Service file not found: $SERVICE_FILE"
    exit 1
fi

echo "Checking/creating videos directory..."
if [ ! -d "$WATCH_DIR" ]; then
    sudo -u "$TARGET_USER" mkdir -p "$WATCH_DIR"
    echo "Directory created: $WATCH_DIR"
else
    echo "Directory already exists: $WATCH_DIR"
fi

SHARE_DIR="$HOME_DIR/.local/share/webm-converter"
if [ -f "dist/icon.png" ]; then
    echo "Copying icon to $SHARE_DIR..."
    sudo -u "$TARGET_USER" mkdir -p "$SHARE_DIR"
    sudo -u "$TARGET_USER" cp "dist/icon.png" "$SHARE_DIR/"
    echo "Icon copied to $SHARE_DIR/icon.png"
fi

echo "Stopping service if running..."
systemctl stop $SERVICE_NAME 2>/dev/null || true

echo "Generating customized service file..."
sed -e "s|{{USER}}|$TARGET_USER|g" \
    -e "s|{{GROUP}}|$TARGET_GROUP|g" \
    -e "s|{{HOME_DIR}}|$HOME_DIR|g" \
    -e "s|{{WORKING_DIR}}|$WORKING_DIR|g" \
    -e "s|{{EXEC_PATH}}|$EXEC_PATH|g" \
    -e "s|{{WATCH_DIR}}|$WATCH_DIR|g" \
    "$SERVICE_FILE" > "$SYSTEMD_DIR/$SERVICE_FILE"

echo "Service file generated at $SYSTEMD_DIR/$SERVICE_FILE"

echo "Reloading systemd daemon..."
systemctl daemon-reload

echo "Enabling service to start automatically..."
systemctl enable $SERVICE_NAME

echo "Starting service..."
systemctl start $SERVICE_NAME

echo "Service status:"
systemctl status $SERVICE_NAME --no-pager

echo ""
echo "Installation completed!"
echo ""
echo "Useful commands:"
echo "  Check status:        sudo systemctl status $SERVICE_NAME"
echo "  Start service:       sudo systemctl start $SERVICE_NAME"
echo "  Stop service:        sudo systemctl stop $SERVICE_NAME"
echo "  Restart service:     sudo systemctl restart $SERVICE_NAME"
echo "  View logs:           sudo journalctl -u $SERVICE_NAME -f"
echo "  Disable:             sudo systemctl disable $SERVICE_NAME"
echo ""
echo "To view logs in real-time:"
echo "  sudo journalctl -u $SERVICE_NAME -f" 