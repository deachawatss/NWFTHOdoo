#!/bin/bash
# Restore script for Odoo 17 Production

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Configuration
DB_HOST="${POSTGRES_HOST:-db}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-odoo_prod}"
DB_USER="${POSTGRES_USER:-odoo_prod}"
DB_PASSWORD="${POSTGRES_PASSWORD}"
BACKUP_DIR="${BACKUP_DIR:-/backup}"
ODOO_DATA_DIR="${ODOO_DATA_DIR:-/var/lib/odoo}"

# Usage function
usage() {
    echo "Usage: $0 [OPTIONS] BACKUP_FILE"
    echo ""
    echo "Options:"
    echo "  -d, --database-only    Restore database only"
    echo "  -f, --filestore-only   Restore filestore only"
    echo "  -n, --new-db-name      Restore to a different database name"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 odoo_full_backup_20240115_120000.tar.gz"
    echo "  $0 -d db_backup_20240115_120000.sql.gz"
    echo "  $0 -n odoo_test odoo_full_backup_20240115_120000.tar.gz"
    exit 1
}

# Function to restore database
restore_database() {
    local db_file="$1"
    local target_db="${2:-$DB_NAME}"
    
    log "Restoring database from: $db_file"
    log "Target database: $target_db"
    
    export PGPASSWORD="${DB_PASSWORD}"
    
    # Check if database exists and drop it
    if psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -lqt | cut -d \| -f 1 | grep -qw "$target_db"; then
        warn "Database $target_db exists. It will be dropped and recreated."
        read -p "Continue? [y/N]: " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            log "Restore cancelled by user"
            exit 0
        fi
        
        # Terminate connections to the database
        psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$target_db';"
        
        # Drop database
        dropdb -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" "$target_db"
        log "Database $target_db dropped"
    fi
    
    # Create new database
    createdb -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" "$target_db"
    log "Database $target_db created"
    
    # Restore database
    if [[ "$db_file" == *.gz ]]; then
        if gunzip -c "$db_file" | psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "$target_db"; then
            log "Database restored successfully"
        else
            error "Database restore failed!"
        fi
    else
        if psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "$target_db" < "$db_file"; then
            log "Database restored successfully"
        else
            error "Database restore failed!"
        fi
    fi
}

# Function to restore filestore
restore_filestore() {
    local filestore_file="$1"
    
    log "Restoring filestore from: $filestore_file"
    
    # Backup existing filestore
    if [ -d "${ODOO_DATA_DIR}/filestore" ]; then
        local backup_timestamp=$(date +'%Y%m%d_%H%M%S')
        mv "${ODOO_DATA_DIR}/filestore" "${ODOO_DATA_DIR}/filestore_backup_${backup_timestamp}"
        log "Existing filestore backed up to filestore_backup_${backup_timestamp}"
    fi
    
    # Extract filestore
    if tar -xzf "$filestore_file" -C "${ODOO_DATA_DIR}"; then
        log "Filestore restored successfully"
    else
        error "Filestore restore failed!"
    fi
    
    # Set proper permissions
    chown -R odoo:odoo "${ODOO_DATA_DIR}/filestore" 2>/dev/null || warn "Could not set filestore permissions"
}

# Function to extract and restore full backup
restore_full_backup() {
    local backup_file="$1"
    local target_db="${2:-$DB_NAME}"
    
    log "Restoring full backup from: $backup_file"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    local cleanup() {
        rm -rf "$temp_dir"
    }
    trap cleanup EXIT
    
    # Extract backup archive
    log "Extracting backup archive..."
    if tar -xzf "$backup_file" -C "$temp_dir"; then
        log "Backup archive extracted successfully"
    else
        error "Failed to extract backup archive!"
    fi
    
    # Find database backup file
    local db_backup=$(find "$temp_dir" -name "db_backup_*.sql.gz" | head -1)
    if [ -z "$db_backup" ]; then
        error "Database backup file not found in archive!"
    fi
    
    # Find filestore backup file
    local filestore_backup=$(find "$temp_dir" -name "filestore_backup_*.tar.gz" | head -1)
    if [ -z "$filestore_backup" ]; then
        warn "Filestore backup file not found in archive!"
    fi
    
    # Restore database
    restore_database "$db_backup" "$target_db"
    
    # Restore filestore if available
    if [ -n "$filestore_backup" ]; then
        restore_filestore "$filestore_backup"
    fi
    
    log "Full backup restore completed successfully!"
}

# Function to list available backups
list_backups() {
    log "Available backup files in ${BACKUP_DIR}:"
    echo ""
    
    find "${BACKUP_DIR}" -name "*backup*.tar.gz" -o -name "*backup*.sql.gz" | sort -r | while read backup; do
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c %y "$backup" 2>/dev/null || stat -f %Sm "$backup" 2>/dev/null || echo "Unknown")
        printf "%-50s %8s %s\n" "$(basename "$backup")" "$size" "$date"
    done
    
    echo ""
}

# Function to verify backup file
verify_backup_file() {
    local backup_file="$1"
    
    if [ ! -f "$backup_file" ]; then
        error "Backup file not found: $backup_file"
    fi
    
    log "Verifying backup file: $backup_file"
    
    if [[ "$backup_file" == *.tar.gz ]]; then
        if tar -tzf "$backup_file" >/dev/null 2>&1; then
            log "Backup file verification successful"
        else
            error "Backup file is corrupted or invalid!"
        fi
    elif [[ "$backup_file" == *.sql.gz ]]; then
        if gunzip -t "$backup_file" 2>/dev/null; then
            log "SQL backup file verification successful"
        else
            error "SQL backup file is corrupted or invalid!"
        fi
    else
        warn "Cannot verify backup file format"
    fi
}

# Main function
main() {
    local database_only=false
    local filestore_only=false
    local new_db_name=""
    local backup_file=""
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--database-only)
                database_only=true
                shift
                ;;
            -f|--filestore-only)
                filestore_only=true
                shift
                ;;
            -n|--new-db-name)
                new_db_name="$2"
                shift 2
                ;;
            -l|--list)
                list_backups
                exit 0
                ;;
            -h|--help)
                usage
                ;;
            -*)
                error "Unknown option: $1"
                ;;
            *)
                backup_file="$1"
                shift
                ;;
        esac
    done
    
    # Check if backup file is provided
    if [ -z "$backup_file" ]; then
        echo "No backup file specified."
        echo ""
        list_backups
        exit 1
    fi
    
    # Handle relative path
    if [[ "$backup_file" != /* ]]; then
        backup_file="${BACKUP_DIR}/${backup_file}"
    fi
    
    # Verify backup file
    verify_backup_file "$backup_file"
    
    # Check database connectivity
    export PGPASSWORD="${DB_PASSWORD}"
    if ! pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}"; then
        error "Cannot connect to database!"
    fi
    
    # Perform restore based on options
    if [[ "$database_only" == true ]]; then
        if [[ "$backup_file" == *filestore* ]]; then
            error "Cannot restore database from filestore backup!"
        fi
        restore_database "$backup_file" "${new_db_name:-$DB_NAME}"
    elif [[ "$filestore_only" == true ]]; then
        if [[ "$backup_file" == *db_backup* ]]; then
            error "Cannot restore filestore from database backup!"
        fi
        restore_filestore "$backup_file"
    else
        # Full restore
        if [[ "$backup_file" == *full_backup* ]]; then
            restore_full_backup "$backup_file" "${new_db_name:-$DB_NAME}"
        elif [[ "$backup_file" == *db_backup* ]]; then
            restore_database "$backup_file" "${new_db_name:-$DB_NAME}"
        elif [[ "$backup_file" == *filestore* ]]; then
            restore_filestore "$backup_file"
        else
            error "Unknown backup file type!"
        fi
    fi
    
    log "Restore process completed successfully!"
}

# Run main function
main "$@"