#!/bin/bash

# Simple Odoo 18 Development Server Startup Script
# For WSL/Linux environments

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages with timestamp
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

# Navigate to the Odoo18 directory
cd "$(dirname "$0")"

info "======================================================"
info "       Starting Odoo 18 Development Server"
info "       Environment: WSL/Linux"
info "======================================================"

# Validate required files exist
log "Validating environment..."
if [ ! -f "odoo-bin" ]; then
    error "odoo-bin not found! Please ensure you're in the correct directory."
fi

if [ ! -f "odoo-dev.conf" ]; then
    error "odoo-dev.conf not found! Configuration file missing."
fi

if [ ! -d "odoo_env" ]; then
    error "Virtual environment 'odoo_env' not found! Please create it first."
fi

# Stop any existing Odoo processes
log "Checking for running Odoo processes..."
if pgrep -f "python.*odoo-bin" > /dev/null; then
    log "Stopping existing Odoo process..."
    pkill -f "python.*odoo-bin"
    sleep 3
fi

# Create directories if they don't exist
mkdir -p logs data

# Activate virtual environment
log "Activating virtual environment..."
source odoo_env/bin/activate

# Validate Python environment
log "Validating Python environment..."
if ! python -c "import odoo" 2>/dev/null; then
    error "Odoo Python package not found! Please install requirements: pip install -r requirements.txt"
fi

# Test database connectivity
log "Testing database connectivity..."
if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    log "Database connection test passed."
else
    error "Database connection failed. Please ensure PostgreSQL is running."
fi

# Get Windows host IP for network access
WINDOWS_IP=$(ip route show default | awk '/default/ {print $3}' | head -1)
if [ -z "$WINDOWS_IP" ]; then
    WINDOWS_IP="192.168.6.42"  # Fallback to your current IP
fi

# Display startup information
info "======================================================"
info "Configuration:"
info "- Mode: Development (reload enabled)"
info "- Config File: odoo-dev.conf"
info "- Network Binding: 0.0.0.0 (all interfaces)"
info "- Admin Password: 1234"
info "======================================================"
info "Access URLs:"
info "- Local access: http://localhost:8069"
info "- Network access: http://$WINDOWS_IP:8069"
info "- Share this with friends: http://$WINDOWS_IP:8069"
info "======================================================"
info "⚠️  First time setup:"
info "1. Run setup-firewall.bat as Administrator on Windows"
info "2. This enables network access for friends"
info "======================================================"

log "Starting Odoo server..."
info "Press Ctrl+C to stop the server"
echo

# Start Odoo in development mode
python odoo-bin -c odoo-dev.conf

echo
info "======================================================"
info "Odoo server stopped."
info "======================================================"