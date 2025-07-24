#!/bin/bash

# Odoo 17 Docker Environment Stop Script

set -e

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Navigate to the script directory
cd "$(dirname "$0")"

info "======================================================"
info "       Stopping Odoo 17 Docker Environment"
info "======================================================"

# Stop and remove containers
log "Stopping Docker containers..."
docker-compose down

# Optional: Remove volumes (uncomment if you want to reset data)
# log "Removing volumes..."
# docker-compose down -v

# Show final status
log "Docker containers stopped successfully!"

info "======================================================"
info "🐳 Odoo Docker Environment Stopped"
info "======================================================"
info "Data preserved in Docker volumes:"
info "- Database data: odoo17_odoo_db_data"
info "- Odoo data: odoo17_odoo_web_data"
info "======================================================"
info "To completely reset (remove all data):"
info "docker-compose down -v"
info "======================================================"