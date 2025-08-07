#!/bin/bash

# Start Odoo 17 Server with Nginx Proxy
# Server Environment - External Access Ready
# Fixed line endings for Linux server

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

# Navigate to the Odoo17 directory
cd "$(dirname "$0")"

info "======================================================"
info "    Starting Odoo 17 SERVER + Nginx"
info "    Environment: WSL Server (External Access)"
info "======================================================"

# Check if nginx is running
log "Checking nginx status..."
if ! systemctl is-active --quiet nginx; then
    log "Starting nginx..."
    sudo systemctl start nginx || error "Failed to start nginx"
    sleep 2
fi

if systemctl is-active --quiet nginx; then
    log "✅ Nginx is running"
else
    error "❌ Nginx failed to start"
fi

# Get IP addresses for server environment
WSL_IP=$(hostname -I | awk '{print $1}')
SERVER_IP="192.168.0.21"  # Your server's external IP

# Validate required files exist
log "Validating environment..."
if [ ! -f "odoo-bin" ]; then
    error "odoo-bin not found! Please ensure you're in the correct directory."
fi

if [ ! -f "odoo.conf" ] && [ ! -f "odoo-dev.conf" ]; then
    error "odoo.conf or odoo-dev.conf not found! Configuration file missing."
fi

# Use odoo.conf if it exists, otherwise odoo-dev.conf
CONFIG_FILE="odoo.conf"
if [ ! -f "odoo.conf" ] && [ -f "odoo-dev.conf" ]; then
    CONFIG_FILE="odoo-dev.conf"
fi

if [ ! -d "odoo_env" ] && [ ! -d "venv" ]; then
    error "Virtual environment not found! Looking for 'odoo_env' or 'venv'."
fi

# Use the virtual environment that exists
VENV_DIR="odoo_env"
if [ ! -d "odoo_env" ] && [ -d "venv" ]; then
    VENV_DIR="venv"
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
log "Activating virtual environment ($VENV_DIR)..."
source $VENV_DIR/bin/activate

# Validate Python environment
log "Validating Python environment..."
if ! python -c "import odoo" 2>/dev/null; then
    error "Odoo Python package not found! Please install requirements."
fi

# Test database connectivity
log "Testing database connectivity..."
if pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    log "Database connection test passed."
else
    log "⚠️ Database connection test failed. Ensure PostgreSQL is running."
fi

# Display startup information
info "======================================================"
info "🖥️ SERVER CONFIGURATION:"
info "- Mode: Production Server"
info "- Config File: $CONFIG_FILE"
info "- Proxy: Nginx reverse proxy on port 80"
info "- Virtual Env: $VENV_DIR"
info "======================================================"
info "🌐 SERVER ACCESS URLS:"
info "- External: http://$SERVER_IP"
info "- Local: http://localhost"
info "- Direct Odoo: http://$SERVER_IP:8069"
info "======================================================"
info "🚀 SERVER FEATURES:"
info "- ✅ Nginx reverse proxy (port 80)"
info "- ✅ External network access"
info "- ✅ Static file caching"
info "- ✅ Gzip compression"
info "- ✅ Security headers"
info "- ✅ Large file upload support (50MB)"
info "======================================================"
info "📡 EXTERNAL ACCESS:"
info "1. Share this URL: http://$SERVER_IP"
info "2. Configure Windows port forwarding (see scripts)"
info "3. Ensure Windows firewall allows connections"
info "4. Anyone can access from internet/network!"
info "======================================================"
info "WSL Internal IP: $WSL_IP"
info "Server External IP: $SERVER_IP"
info "======================================================"

log "Starting Odoo server behind nginx proxy..."
info "Press Ctrl+C to stop server"
echo

# Function to cleanup on exit
cleanup() {
    echo
    info "======================================================"
    info "Stopping Odoo server..."
    log "Odoo server stopped."
    info "Nginx continues running for other services."
    info "To stop nginx: sudo systemctl stop nginx"
    info "======================================================"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Start Odoo in production mode
python odoo-bin -c $CONFIG_FILE