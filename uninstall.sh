#!/bin/bash

set -e

INSTALL_DIR="$HOME/.local/webm-converter"
BIN_DIR="$HOME/.local/bin"
SHARE_DIR="$HOME/.local/share/webm-converter"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_status "Starting WebM Converter uninstallation..."

if systemctl is-active --quiet webm-converter 2>/dev/null; then
    print_status "Stopping systemd service..."
    sudo systemctl stop webm-converter
fi

if systemctl is-enabled --quiet webm-converter 2>/dev/null; then
    print_status "Disabling systemd service..."
    sudo systemctl disable webm-converter
fi

if [ -f "/etc/systemd/system/webm-converter.service" ]; then
    print_status "Removing service file..."
    sudo rm -f /etc/systemd/system/webm-converter.service
    sudo systemctl daemon-reload
    sudo systemctl reset-failed 2>/dev/null || true
fi

if [ -f "$BIN_DIR/webm-converter" ]; then
    print_status "Removing executable..."
    rm -f "$BIN_DIR/webm-converter"
fi

if [ -d "$INSTALL_DIR" ]; then
    print_status "Removing installation files..."
    rm -rf "$INSTALL_DIR"
fi

if [ -d "$SHARE_DIR" ]; then
    print_status "Removing icon and shared files..."
    rm -rf "$SHARE_DIR"
fi

if [ -f "/tmp/webm-converter-ffmpeg" ]; then
    print_status "Cleaning temporary files..."
    rm -f /tmp/webm-converter-ffmpeg
fi

if [ -d "$HOME/Videos/Screencasts" ]; then
    echo ""
    read -p "Do you want to remove the directory $HOME/Videos/Screencasts? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing videos directory..."
        rm -rf "$HOME/Videos/Screencasts"
    else
        print_warning "Videos directory kept: $HOME/Videos/Screencasts"
    fi
fi

if command -v ffmpeg &> /dev/null; then
    echo ""
    read -p "Do you want to remove FFmpeg from the system? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Removing FFmpeg..."
        if sudo apt remove --purge -y ffmpeg; then
            print_success "FFmpeg removed successfully!"
            echo ""
            read -p "Do you want to remove orphaned packages? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_status "Removing orphaned packages..."
                sudo apt autoremove -y
            fi
        else
            print_warning "Failed to remove FFmpeg."
        fi
    else
        print_warning "FFmpeg kept in the system"
    fi
fi

print_success "Uninstallation completed!"
echo ""
print_warning "Note: PATH entries in ~/.bashrc, ~/.zshrc or ~/.profile"
print_warning "were not removed automatically. If desired, remove the line:"
print_warning "   export PATH=\"\$HOME/.local/bin:\$PATH\""
echo ""
print_success "WebM Converter has been completely removed from the system!" 