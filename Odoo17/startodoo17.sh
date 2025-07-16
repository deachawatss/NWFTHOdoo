#!/bin/bash

# Enhanced Odoo 17 Development Server Script
# This script provides better error handling, logging, and validation

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages with timestamp
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
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
info "       Starting Odoo 17 Development Server"
info "======================================================"

# Validate required files exist
log "Validating environment..."
if [ ! -f "odoo-bin" ]; then
    error "odoo-bin not found! Please ensure you're in the correct directory."
fi

if [ ! -f "odoo.conf" ]; then
    error "odoo.conf not found! Please ensure configuration file exists."
fi

if [ ! -d "odoo_env" ]; then
    error "Virtual environment 'odoo_env' not found! Please create it first."
fi

if [ ! -f "odoo_env/bin/activate" ]; then
    error "Virtual environment activation script not found!"
fi

# Check if there are any running Odoo processes before stopping them
log "Checking for running Odoo processes..."
if pgrep -f "python.*odoo-bin" > /dev/null; then
    warn "Found running Odoo process. Stopping it..."
    pkill -f "python.*odoo-bin"
    sleep 3
    log "Existing Odoo process stopped."
else
    log "No running Odoo process found."
fi

# Handle log file cleanup
log "Preparing log file..."
if [ -f "odoo.log" ]; then
    # Archive old log with timestamp
    mv odoo.log "odoo.log.$(date +'%Y%m%d_%H%M%S')"
    log "Old log file archived."
fi

# Activate virtual environment
log "Activating virtual environment..."
source odoo_env/bin/activate

# Validate Python environment
log "Validating Python environment..."
if ! python -c "import odoo" 2>/dev/null; then
    error "Odoo Python package not found! Please install requirements: pip install -r requirements.txt"
fi

# Check database connectivity (if configured)
log "Checking configuration..."
if [ -f "odoo.conf" ]; then
    DB_HOST=$(grep -E "^db_host" odoo.conf | cut -d'=' -f2 | tr -d ' ' || echo "localhost")
    DB_PORT=$(grep -E "^db_port" odoo.conf | cut -d'=' -f2 | tr -d ' ' || echo "5432")
    
    if command -v pg_isready > /dev/null 2>&1; then
        if pg_isready -h "$DB_HOST" -p "$DB_PORT" > /dev/null 2>&1; then
            log "Database connection test passed."
        else
            warn "Database connection test failed. Odoo will try to connect on startup."
        fi
    else
        log "pg_isready not available. Skipping database connectivity check."
    fi
fi

# Display startup information
info "======================================================"
info "Configuration:"
info "- Mode: Development (reload, qweb, werkzeug, xml)"
info "- Log Level: Info"
info "- Config File: odoo.conf"
info "- Log File: odoo.log"
info "======================================================"

log "Starting Odoo server..."
info "Press Ctrl+C to stop the server"
echo

# Run Odoo in development mode and show log while saving to file
python odoo-bin -c odoo.conf --dev=reload,qweb,werkzeug,xml --log-level=info 2>&1 | tee odoo.log

# This will only run if Odoo exits normally (not with Ctrl+C)
echo
info "======================================================"
info "Odoo server stopped."
info "Log file saved as: odoo.log"
info "======================================================"

# Wait for user input before closing (equivalent to Windows pause)
read -p "Press Enter to continue..."