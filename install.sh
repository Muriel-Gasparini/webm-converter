#!/bin/bash

set -euo pipefail

export LC_ALL=C.UTF-8 2>/dev/null || export LC_ALL=C 2>/dev/null || true

REPO_URL="https://github.com/Muriel-Gasparini/webm-converter"
RELEASE_VERSION="v1.0.0"
BINARY_URL="$REPO_URL/releases/download/$RELEASE_VERSION/webm-converter"
ICON_URL="$REPO_URL/raw/$RELEASE_VERSION/icon.png"
SERVICE_URL="$REPO_URL/raw/$RELEASE_VERSION/webm-converter.service"
INSTALL_SERVICE_URL="$REPO_URL/raw/$RELEASE_VERSION/install-service.sh"

BIN_DIR="$HOME/.local/bin"
SHARE_DIR="$HOME/.local/share/webm-converter"
SERVICE_DIR="/tmp/webm-converter-install"

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

if [ "$EUID" -eq 0 ]; then
    print_error "Do not run as root! Run as normal user."
    exit 1
fi

print_status "Starting WebM Converter $RELEASE_VERSION installation..."

print_status "Checking dependencies..."

if ! command -v curl &> /dev/null && ! command -v wget &> /dev/null; then
    print_error "curl or wget not found!"
    print_status "Install curl: sudo apt install curl"
    exit 1
fi

if ! command -v ffmpeg &> /dev/null; then
    print_status "FFmpeg not found. Installing via apt..."
    if sudo apt update && sudo apt install -y ffmpeg; then
        print_success "FFmpeg installed successfully!"
    else
        print_error "Failed to install FFmpeg!"
        exit 1
    fi
else
    print_success "FFmpeg is already installed"
    ffmpeg -version | head -1
fi

print_status "Creating directories..."
mkdir -p "$BIN_DIR"
mkdir -p "$SHARE_DIR"
mkdir -p "$HOME/Videos/Screencasts"
mkdir -p "$SERVICE_DIR"

download_file() {
    local url="$1"
    local output="$2"

    if command -v curl &> /dev/null; then
        curl -fsSL "$url" -o "$output"
    else
        wget -q "$url" -O "$output"
    fi
}

print_status "Downloading WebM Converter $RELEASE_VERSION..."
if ! download_file "$BINARY_URL" "$BIN_DIR/webm-converter"; then
    print_error "Failed to download executable!"
    print_error "Check if release $RELEASE_VERSION exists at: $REPO_URL/releases"
    exit 1
fi

print_status "Downloading icon..."
if ! download_file "$ICON_URL" "$SHARE_DIR/icon.png"; then
    print_warning "Failed to download icon. Notifications will be without icon."
fi

chmod +x "$BIN_DIR/webm-converter"

if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
    print_status "Adding to PATH..."

    if [ -n "$ZSH_VERSION" ]; then
        SHELL_RC="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        SHELL_RC="$HOME/.bashrc"
    else
        SHELL_RC="$HOME/.profile"
    fi

    if ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$SHELL_RC" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$SHELL_RC"
        print_success "PATH updated in $SHELL_RC"
        print_warning "Restart terminal or run: source $SHELL_RC"
    fi

    export PATH="$HOME/.local/bin:$PATH"
fi

if [ -t 0 ]; then
    INTERACTIVE=true
else
    INTERACTIVE=false
fi

if [ "$INTERACTIVE" = true ]; then
    echo ""
    read -p "Do you want to install as systemd service? (y/N): " -n 1 -r
    echo ""
    INSTALL_SERVICE="$REPLY"
else
    print_status "Non-interactive mode detected. Installing systemd service..."
    INSTALL_SERVICE="y"
fi

if [[ $INSTALL_SERVICE =~ ^[Yy]$ ]]; then
    print_status "Downloading systemd service files..."

    if download_file "$SERVICE_URL" "$SERVICE_DIR/webm-converter.service" && \
       download_file "$INSTALL_SERVICE_URL" "$SERVICE_DIR/install-service.sh"; then

        cd "$SERVICE_DIR" || exit 1
        chmod +x install-service.sh

        if [ -n "${SUDO_USER:-}" ]; then
            TARGET_USER="$SUDO_USER"
        else
            TARGET_USER="$(whoami)"
        fi
        TARGET_GROUP="$(id -gn $TARGET_USER)"
        HOME_DIR="$(eval echo ~$TARGET_USER)"
        WORKING_DIR="$HOME_DIR"
        EXEC_PATH="$BIN_DIR/webm-converter"
        WATCH_DIR="$HOME_DIR/Videos/Screencasts"

        print_status "Configuring service for user: $TARGET_USER"

        sed -e "s|{{USER}}|$TARGET_USER|g" \
            -e "s|{{GROUP}}|$TARGET_GROUP|g" \
            -e "s|{{HOME_DIR}}|$HOME_DIR|g" \
            -e "s|{{WORKING_DIR}}|$WORKING_DIR|g" \
            -e "s|{{EXEC_PATH}}|$EXEC_PATH|g" \
            -e "s|{{WATCH_DIR}}|$WATCH_DIR|g" \
            webm-converter.service > webm-converter-configured.service

        if grep -q "{{" webm-converter-configured.service; then
            print_error "Error: Some placeholders were not replaced in service file"
            cat webm-converter-configured.service | grep "{{"
            print_warning "Failed to configure service. Continue with manual installation."
        else
            print_status "Installing systemd service..."
            if sudo cp webm-converter-configured.service /etc/systemd/system/webm-converter.service && \
               sudo systemctl daemon-reload && \
               sudo systemctl enable webm-converter && \
               sudo systemctl start webm-converter; then
                print_success "Service installed and started!"
            else
                print_warning "Failed to install service. Continue with manual installation."
            fi
        fi
    else
        print_warning "Failed to download service files."
    fi
fi

rm -rf "$SERVICE_DIR"

if [ -x "$BIN_DIR/webm-converter" ]; then
    print_success "Installation completed successfully!"
else
    print_error "Installation error: executable not found"
    exit 1
fi

printf "\n"
printf "Usage:\n"
printf "  Run once:           webm-converter\n"
printf "  Service status:     sudo systemctl status webm-converter\n"
printf "  View logs:          sudo journalctl -u webm-converter -f\n"
printf "  Stop service:       sudo systemctl stop webm-converter\n"
printf "  Start service:      sudo systemctl start webm-converter\n"
printf "\n"
printf "Monitored directory: %s\n" "$HOME/Videos/Screencasts"
printf "Executable: %s\n" "$BIN_DIR/webm-converter"
printf "Version: %s\n" "$RELEASE_VERSION"
printf "\n"
printf "Now record your screen with Gnome ScreenCast and .webm files\n"
printf "will be automatically converted to .mp4!\n" 