#!/bin/bash

# Start Odoo 17 Development Server with Nginx Proxy
# This script starts both Odoo and ensures nginx is running

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
info "    Starting Odoo 17 + Nginx Development Server"
info "    Environment: WSL/Linux with Nginx Reverse Proxy"
info "======================================================"

# Check if nginx is running
log "Checking nginx status..."
if ! systemctl is-active --quiet nginx; then
    log "Starting nginx..."
    echo "1234" | sudo -S systemctl start nginx || error "Failed to start nginx"
    sleep 2
fi

if systemctl is-active --quiet nginx; then
    log "✅ Nginx is running"
else
    error "❌ Nginx failed to start"
fi

# Get IP addresses
LOCAL_IP=$(hostname -I | awk '{print $1}')
GATEWAY_IP=$(ip route show default | awk '/default/ {print $3}' | head -1)

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

# Display startup information
info "======================================================"
info "Configuration:"
info "- Mode: Development (reload enabled)"
info "- Config File: odoo-dev.conf"  
info "- Proxy: Nginx reverse proxy on port 80"
info "- Odoo Backend: localhost:8069 (internal)"
info "- Admin Password: 1234"
info "======================================================"
info "🌐 Access URLs:"
info "- Local access: http://localhost"
info "- Network access: http://$LOCAL_IP"
info "- Share with others: http://$LOCAL_IP"
info "======================================================"
info "🚀 Network Features:"
info "- ✅ Nginx reverse proxy (port 80)"
info "- ✅ Static file caching"
info "- ✅ Gzip compression"
info "- ✅ Security headers"
info "- ✅ Large file upload support (50MB)"
info "======================================================"
info "📱 For external access:"
info "1. Share this URL: http://$LOCAL_IP"
info "2. Ensure Windows firewall allows connections"
info "3. Your friends can access from any device!"
info "======================================================"

log "Starting Odoo server behind nginx proxy..."
info "Press Ctrl+C to stop both Odoo and nginx"
echo

# Function to cleanup on exit
cleanup() {
    echo
    info "======================================================"
    info "Stopping services..."
    log "Odoo server stopped."
    info "Nginx will continue running for other services."
    info "To stop nginx: sudo systemctl stop nginx"
    info "======================================================"
}

# Set trap to cleanup on exit
trap cleanup EXIT INT TERM

# Start Odoo in development mode
python odoo-bin -c odoo-dev.conf