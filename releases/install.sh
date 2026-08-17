#!/bin/bash
# Ganzo App Install Script for Linux
# Usage: curl -fsSL https://raw.githubusercontent.com/ganzoai/ganzo/main/releases/install.sh | bash
#
# Detects architecture (x86_64 or aarch64), downloads the correct .deb
# from GitHub Releases on ganzoai/ganzo, installs it, and sets up a
# systemd service for background operation.
set -e

GANZO_REPO="ganzoai/ganzo"
GANZO_RELEASES_URL="https://github.com/${GANZO_REPO}/releases"
LATEST_JSON_URL="https://raw.githubusercontent.com/${GANZO_REPO}/main/releases/latest.json"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Ganzo App Installer (Linux) ===${NC}"
echo ""

# Detect architecture
ARCH="$(uname -m)"
OS="$(uname -s)"

if [ "$OS" != "Linux" ]; then
    echo -e "${RED}This script is for Linux only.${NC}"
    echo -e "macOS: Download the .dmg from ${GANZO_RELEASES_URL}"
    echo -e "Windows: Download the .exe from ${GANZO_RELEASES_URL}"
    echo -e "Android/iOS: Install from Google Play Store / Apple App Store"
    exit 1
fi

echo -e "Detected: Linux on ${ARCH}"

# Get latest version from latest.json
echo -e "Fetching latest version..."
LATEST_JSON=$(curl -fsSL "$LATEST_JSON_URL" 2>/dev/null || echo "")
if [ -z "$LATEST_JSON" ]; then
    echo -e "${RED}Error: Could not fetch latest.json${NC}"
    echo -e "Visit ${GANZO_RELEASES_URL} to download manually"
    exit 1
fi

GANZO_VERSION=$(echo "$LATEST_JSON" | grep -o '"version": *"[^"]*"' | head -1 | sed 's/.*"version": *"//;s/"//')
if [ -z "$GANZO_VERSION" ]; then
    echo -e "${RED}Error: Could not parse version from latest.json${NC}"
    exit 1
fi
echo -e "Latest version: ${GREEN}${GANZO_VERSION}${NC}"
echo ""

# Platform-specific download URL
case "$ARCH" in
    x86_64|amd64)
        DEB_FILE="ganzo_${GANZO_VERSION}_amd64.deb"
        ;;
    aarch64|arm64)
        DEB_FILE="ganzo_${GANZO_VERSION}_arm64.deb"
        ;;
    *)
        echo -e "${RED}Error: Unsupported architecture ${ARCH}${NC}"
        echo -e "Supported: x86_64 (amd64), aarch64 (arm64)"
        exit 1
        ;;
esac

DOWNLOAD_URL="${GANZO_RELEASES_URL}/download/v${GANZO_VERSION}/${DEB_FILE}"

# Download
echo -e "Downloading: ${DEB_FILE}"
TMP_DIR=$(mktemp -d)
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL -o "${TMP_DIR}/${DEB_FILE}" "$DOWNLOAD_URL" || {
    echo -e "${RED}Error: Download failed. The release may not have a Linux ${ARCH} build yet.${NC}"
    echo -e "URL: ${DOWNLOAD_URL}"
    echo -e "Check available downloads at ${GANZO_RELEASES_URL}"
    exit 1
}
echo -e "${GREEN}Downloaded: ${DEB_FILE}${NC}"
echo ""

# Install
echo -e "Installing Ganzo ${GANZO_VERSION}..."
sudo dpkg -i "${TMP_DIR}/${DEB_FILE}" 2>/dev/null || sudo apt-get install -f -y
echo -e "${GREEN}Installed to /usr/local/bin/ganzo-app${NC}"
echo ""

# Set up systemd service
echo -e "Setting up systemd service..."
SERVICE_FILE="/etc/systemd/system/ganzo.service"
sudo tee "$SERVICE_FILE" > /dev/null << 'EOF'
[Unit]
Description=Ganzo App - P2P AI Agent Network
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/ganzo-app
Restart=on-failure
RestartSec=10
Environment=RUST_LOG=error
WorkingDirectory=/var/lib/ganzo
StateDirectory=ganzo
CacheDirectory=ganzo
LogsDirectory=ganzo

[Install]
WantedBy=multi-user.target
EOF

sudo mkdir -p /var/lib/ganzo
sudo chown -R $USER:$USER /var/lib/ganzo

sudo systemctl daemon-reload
sudo systemctl enable ganzo.service
sudo systemctl start ganzo.service

echo -e "${GREEN}Systemd service created and started!${NC}"
echo ""
echo -e "${BLUE}=== Installation Complete ===${NC}"
echo ""
echo -e "Service commands:"
echo -e "  ${YELLOW}sudo systemctl status ganzo${NC}     - Check status"
echo -e "  ${YELLOW}sudo systemctl restart ganzo${NC}    - Restart"
echo -e "  ${YELLOW}sudo systemctl stop ganzo${NC}        - Stop"
echo -e "  ${YELLOW}journalctl -u ganzo -f${NC}            - View logs"
echo ""
echo -e "Ganzo will auto-update via the built-in Tauri updater."
echo -e "All nodes must run the same version for P2P consensus."