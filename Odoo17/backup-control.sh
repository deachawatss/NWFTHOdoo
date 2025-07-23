#!/bin/bash
# Manual backup control script for Odoo 17 Production

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

show_usage() {
    echo "Usage: $0 {start|stop|status|logs|run-once|schedule}"
    echo ""
    echo "Commands:"
    echo "  start     - Start backup service (manual mode)"
    echo "  stop      - Stop backup service"
    echo "  status    - Check backup service status"
    echo "  logs      - View backup service logs"
    echo "  run-once  - Run a single backup immediately"
    echo "  schedule  - Start backup service with daily scheduling"
    echo ""
    echo "Examples:"
    echo "  $0 run-once    # Run backup right now"
    echo "  $0 schedule    # Start daily automatic backups"
    echo "  $0 status      # Check if backup is running"
}

# Function to check if main services are running
check_main_services() {
    if ! docker-compose ps | grep -q "odoo17_db.*Up.*healthy"; then
        error "Database service is not healthy. Cannot proceed with backup."
        return 1
    fi
    
    info "Main services are ready for backup"
    return 0
}

# Function to run backup once
run_backup_once() {
    log "Starting one-time backup..."
    
    if ! check_main_services; then
        exit 1
    fi
    
    # Run backup service with profile
    if docker-compose --profile backup run --rm backup; then
        log "✓ Backup completed successfully!"
        
        # Show backup statistics
        if [ -d "./backup" ]; then
            local backup_count=$(find ./backup -name "*backup*.tar.gz" -type f | wc -l)
            local total_size=$(du -sh ./backup 2>/dev/null | cut -f1 || echo "Unknown")
            info "Backup statistics:"
            info "  • Total backups: $backup_count"
            info "  • Total size: $total_size"
            info "  • Location: $(pwd)/backup"
        fi
    else
        error "Backup failed!"
        exit 1
    fi
}

# Function to start scheduled backup service
start_scheduled_backup() {
    log "Starting scheduled backup service (daily)..."
    
    if ! check_main_services; then
        exit 1
    fi
    
    # Set environment variable for continuous mode
    export BACKUP_INTERVAL=86400  # 24 hours
    
    if docker-compose --profile backup up -d backup; then
        log "✓ Scheduled backup service started"
        info "Backups will run every 24 hours"
        info "Use '$0 logs' to monitor backup activity"
        info "Use '$0 stop' to stop scheduled backups"
    else
        error "Failed to start scheduled backup service"
        exit 1
    fi
}

# Function to stop backup service
stop_backup() {
    log "Stopping backup service..."
    
    if docker-compose stop backup 2>/dev/null; then
        log "✓ Backup service stopped"
    else
        warn "Backup service was not running"
    fi
    
    # Remove container if it exists
    docker-compose rm -f backup 2>/dev/null || true
}

# Function to check backup status
check_backup_status() {
    info "Checking backup service status..."
    
    if docker-compose ps backup | grep -q "Up"; then
        log "✓ Backup service is running (scheduled mode)"
        
        # Show next backup time if logs are available
        if docker-compose logs backup 2>/dev/null | tail -10 | grep -q "Waiting.*before next backup"; then
            info "Scheduled backups are active"
        fi
    else
        info "Backup service is stopped (manual mode)"
    fi
    
    # Show backup directory statistics
    if [ -d "./backup" ]; then
        local backup_count=$(find ./backup -name "*backup*.tar.gz" -type f 2>/dev/null | wc -l)
        local total_size=$(du -sh ./backup 2>/dev/null | cut -f1 || echo "Unknown")
        local latest_backup=$(find ./backup -name "*backup*.tar.gz" -type f -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -1 | cut -d' ' -f2- | xargs basename 2>/dev/null || echo "None")
        
        info "Backup directory status:"
        info "  • Total backups: $backup_count"
        info "  • Total size: $total_size"
        info "  • Latest backup: $latest_backup"
        info "  • Location: $(pwd)/backup"
    else
        warn "Backup directory not found"
    fi
}

# Function to show logs
show_logs() {
    info "Showing backup service logs (last 50 lines)..."
    echo ""
    
    if docker-compose logs --tail=50 backup 2>/dev/null; then
        echo ""
        info "Use 'docker-compose logs -f backup' to follow logs in real-time"
    else
        warn "No backup service logs available"
        info "Run a backup first with '$0 run-once'"
    fi
}

# Main script logic
case "${1:-}" in
    start)
        start_scheduled_backup
        ;;
    stop)
        stop_backup
        ;;
    status)
        check_backup_status
        ;;
    logs)
        show_logs
        ;;
    run-once)
        run_backup_once
        ;;
    schedule)
        start_scheduled_backup
        ;;
    *)
        show_usage
        exit 1
        ;;
esac