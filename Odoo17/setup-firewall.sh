#!/bin/bash

# Firewall Setup Script for Odoo with Nginx
# This script configures UFW firewall for external access

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

info "======================================================"
info "     Odoo Firewall Setup (UFW Configuration)"
info "======================================================"

# Check if UFW is installed
if ! command -v ufw &> /dev/null; then
    log "Installing UFW firewall..."
    echo "1234" | sudo -S apt update && echo "1234" | sudo -S apt install ufw -y
fi

log "Configuring UFW firewall rules..."

# Reset UFW to defaults (optional, be careful on production systems)
warning "This will reset UFW rules to defaults. Continue? (Ctrl+C to cancel)"
sleep 5

echo "1234" | sudo -S ufw --force reset

# Set default policies
echo "1234" | sudo -S ufw default deny incoming
echo "1234" | sudo -S ufw default allow outgoing

# Allow SSH (important!)
echo "1234" | sudo -S ufw allow ssh
echo "1234" | sudo -S ufw allow 22

# Allow HTTP and HTTPS
echo "1234" | sudo -S ufw allow 80
echo "1234" | sudo -S ufw allow 443

# Allow Odoo port (for direct access if needed)
echo "1234" | sudo -S ufw allow 8069

# Allow PostgreSQL (if needed for remote connections)
# echo "1234" | sudo -S ufw allow 5432

# Enable UFW
echo "1234" | sudo -S ufw --force enable

# Show status
info "======================================================"
info "UFW Firewall Status:"
info "======================================================"
echo "1234" | sudo -S ufw status verbose

info "======================================================"
info "Firewall Configuration Complete!"
info ""
info "Allowed Ports:"
info "- Port 22 (SSH) ✅"
info "- Port 80 (HTTP/Nginx) ✅"
info "- Port 443 (HTTPS) ✅"
info "- Port 8069 (Odoo Direct) ✅"
info ""
info "Your Odoo server is now accessible from:"
info "- Local: http://localhost"
info "- Network: http://$(hostname -I | awk '{print $1}')"
info "======================================================"