#!/bin/bash

# Odoo 17 Docker Development Environment Startup Script
# Maintains compatibility with your current development workflow

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

warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Navigate to the script directory
cd "$(dirname "$0")"

info "======================================================"
info "       Starting Odoo 17 Docker Environment"
info "       Same credentials as your dev setup"
info "======================================================"

# Check if Docker is running
log "Checking Docker availability..."
if ! docker info > /dev/null 2>&1; then
    error "Docker is not running! Please start Docker Desktop or Docker daemon."
fi

# Check if docker-compose is available
if ! command -v docker-compose > /dev/null 2>&1; then
    error "docker-compose not found! Please install docker-compose."
fi

# Create necessary directories
log "Creating necessary directories..."
mkdir -p logs config

# Check for custom addons
if [ -d "custom_addons" ]; then
    log "Found custom addons directory with $(ls -1 custom_addons | wc -l) modules"
else
    warning "No custom_addons directory found. Creating empty one..."
    mkdir -p custom_addons
fi

# Stop any existing containers
log "Stopping any existing Odoo containers..."
docker-compose down > /dev/null 2>&1 || true

# Pull latest images
log "Pulling latest Docker images..."
docker-compose pull

# Start the services
log "Starting Odoo services..."
docker-compose up -d

# Wait for services to be ready
log "Waiting for services to start..."
sleep 10

# Check service status
log "Checking service status..."
if docker-compose ps | grep -q "Up"; then
    log "Services started successfully!"
else
    error "Some services failed to start. Check logs with: docker-compose logs"
fi

# Display connection information
info "======================================================"
info "🐳 Docker Services Started Successfully!"
info "======================================================"
info "Configuration:"
info "- Environment: Docker containers"
info "- Database: PostgreSQL in container"
info "- Credentials: admin/1234 (same as your dev setup)"
info "- Development mode: Enabled with auto-reload"
info "======================================================"
info "Access URLs:"
info "- Odoo Application: http://localhost:8069"
info "- PgAdmin (Database): http://localhost:8080"
info "- Database Direct: localhost:5432"
info "======================================================"
info "Database Connection:"
info "- Host: localhost (or db from within containers)"
info "- Port: 5432"
info "- Database: postgres"
info "- Username: admin"
info "- Password: 1234"
info "======================================================"
info "Docker Commands:"
info "- View logs: docker-compose logs -f"
info "- Stop services: docker-compose down"
info "- Restart Odoo: docker-compose restart odoo"
info "- Shell access: docker-compose exec odoo bash"
info "======================================================"

# Optional: Show container status
log "Container status:"
docker-compose ps

info "✅ Your Odoo 17 Docker environment is ready!"
info "Same credentials, same functionality, now in Docker! 🚀"