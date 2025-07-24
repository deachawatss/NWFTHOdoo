#!/bin/bash

# Odoo 17 Docker Logs Viewer Script

set -e

# Color codes for output
GREEN='\033[0;32m'
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

SERVICE=${1:-all}

case $SERVICE in
    "odoo"|"app")
        log "Showing Odoo application logs..."
        docker-compose logs -f odoo
        ;;
    "db"|"postgres")
        log "Showing PostgreSQL database logs..."
        docker-compose logs -f db
        ;;
    "pgadmin")
        log "Showing PgAdmin logs..."
        docker-compose logs -f pgadmin
        ;;
    "all"|*)
        log "Showing all service logs..."
        info "Press Ctrl+C to stop viewing logs"
        docker-compose logs -f
        ;;
esac