#!/bin/bash
# Automated backup script for Odoo 17 Production

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

# Configuration from environment variables
DB_HOST="${POSTGRES_HOST:-db}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_NAME="${POSTGRES_DB:-odoo_prod}"
DB_USER="${POSTGRES_USER:-odoo_prod}"
DB_PASSWORD="${POSTGRES_PASSWORD}"
BACKUP_DIR="${BACKUP_DIR:-/backup}"
RETENTION_DAYS="${BACKUP_RETENTION_DAYS:-7}"
ODOO_DATA_DIR="${ODOO_DATA_DIR:-/var/lib/odoo}"

# Backup file naming
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')
DB_BACKUP_FILE="db_backup_${TIMESTAMP}.sql.gz"
FILESTORE_BACKUP_FILE="filestore_backup_${TIMESTAMP}.tar.gz"
FULL_BACKUP_FILE="odoo_full_backup_${TIMESTAMP}.tar.gz"

# Ensure backup directory exists
mkdir -p "${BACKUP_DIR}"

# Function to backup database
backup_database() {
    log "Starting database backup..."
    
    export PGPASSWORD="${DB_PASSWORD}"
    
    if pg_dump -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" --verbose | gzip > "${BACKUP_DIR}/${DB_BACKUP_FILE}"; then
        log "Database backup completed: ${DB_BACKUP_FILE}"
        log "Database backup size: $(du -h "${BACKUP_DIR}/${DB_BACKUP_FILE}" | cut -f1)"
    else
        error "Database backup failed!"
    fi
}

# Function to backup filestore
backup_filestore() {
    log "Starting filestore backup..."
    
    if [ -d "${ODOO_DATA_DIR}/filestore" ]; then
        if tar -czf "${BACKUP_DIR}/${FILESTORE_BACKUP_FILE}" -C "${ODOO_DATA_DIR}" filestore/; then
            log "Filestore backup completed: ${FILESTORE_BACKUP_FILE}"
            log "Filestore backup size: $(du -h "${BACKUP_DIR}/${FILESTORE_BACKUP_FILE}" | cut -f1)"
        else
            error "Filestore backup failed!"
        fi
    else
        warn "Filestore directory not found at ${ODOO_DATA_DIR}/filestore"
    fi
}

# Function to create full backup
create_full_backup() {
    log "Creating full backup archive..."
    
    cd "${BACKUP_DIR}"
    
    if tar -czf "${FULL_BACKUP_FILE}" "${DB_BACKUP_FILE}" "${FILESTORE_BACKUP_FILE}"; then
        log "Full backup created: ${FULL_BACKUP_FILE}"
        log "Full backup size: $(du -h "${FULL_BACKUP_FILE}" | cut -f1)"
        
        # Remove individual backup files
        rm -f "${DB_BACKUP_FILE}" "${FILESTORE_BACKUP_FILE}"
        log "Individual backup files cleaned up"
    else
        error "Failed to create full backup archive!"
    fi
}

# Function to clean old backups
cleanup_old_backups() {
    log "Cleaning up backups older than ${RETENTION_DAYS} days..."
    
    find "${BACKUP_DIR}" -name "*.tar.gz" -type f -mtime +${RETENTION_DAYS} -delete
    find "${BACKUP_DIR}" -name "*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete
    
    REMAINING_BACKUPS=$(find "${BACKUP_DIR}" -name "*backup*.tar.gz" -type f | wc -l)
    log "Cleanup completed. ${REMAINING_BACKUPS} backup files remaining."
}

# Function to verify backup integrity
verify_backup() {
    log "Verifying backup integrity..."
    
    if [ -f "${BACKUP_DIR}/${FULL_BACKUP_FILE}" ]; then
        if tar -tzf "${BACKUP_DIR}/${FULL_BACKUP_FILE}" >/dev/null 2>&1; then
            log "Backup integrity verified successfully"
        else
            error "Backup integrity check failed!"
        fi
    else
        error "Backup file not found for verification!"
    fi
}

# Function to send notification (if configured)
send_notification() {
    local status="$1"
    local message="$2"
    
    if [ -n "${BACKUP_WEBHOOK_URL}" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"Odoo Backup ${status}: ${message}\"}" \
            "${BACKUP_WEBHOOK_URL}" || warn "Failed to send notification"
    fi
    
    if [ -n "${BACKUP_EMAIL}" ] && command -v mail >/dev/null 2>&1; then
        echo "${message}" | mail -s "Odoo Backup ${status}" "${BACKUP_EMAIL}" || warn "Failed to send email notification"
    fi
}

# Function to upload to cloud storage (if configured)
upload_to_cloud() {
    if [ -n "${AWS_ACCESS_KEY_ID}" ] && [ -n "${AWS_SECRET_ACCESS_KEY}" ] && [ -n "${AWS_S3_BUCKET}" ]; then
        log "Uploading backup to AWS S3..."
        
        aws s3 cp "${BACKUP_DIR}/${FULL_BACKUP_FILE}" "s3://${AWS_S3_BUCKET}/odoo-backups/" || warn "Failed to upload to S3"
        
        log "Backup uploaded to S3 successfully"
    fi
}

# Function to log backup statistics
log_backup_stats() {
    local backup_size=$(du -h "${BACKUP_DIR}/${FULL_BACKUP_FILE}" | cut -f1)
    local total_backups=$(find "${BACKUP_DIR}" -name "*backup*.tar.gz" -type f | wc -l)
    local total_size=$(du -sh "${BACKUP_DIR}" | cut -f1)
    
    log "=== Backup Statistics ==="
    log "Current backup size: ${backup_size}"
    log "Total backups: ${total_backups}"
    log "Total backup directory size: ${total_size}"
    log "========================="
}

# Main backup function
main() {
    log "Starting Odoo production backup process..."
    log "Database: ${DB_NAME}@${DB_HOST}:${DB_PORT}"
    log "Backup directory: ${BACKUP_DIR}"
    log "Retention period: ${RETENTION_DAYS} days"
    
    # Check database connectivity
    export PGPASSWORD="${DB_PASSWORD}"
    if ! pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}"; then
        error "Cannot connect to database!"
    fi
    
    # Perform backup steps
    backup_database
    backup_filestore
    create_full_backup
    verify_backup
    cleanup_old_backups
    upload_to_cloud
    log_backup_stats
    
    log "Backup process completed successfully!"
    send_notification "SUCCESS" "Backup completed successfully at $(date)"
}

# Error handling
trap 'error "Backup process failed with exit code $?"' ERR

# Continuous backup mode (if BACKUP_INTERVAL is set)
if [ -n "${BACKUP_INTERVAL}" ]; then
    log "Starting continuous backup mode with interval: ${BACKUP_INTERVAL}"
    
    while true; do
        # Check if database is available before backup
        if pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" 2>/dev/null; then
            main
        else
            warn "Database not ready, waiting..."
        fi
        log "Waiting ${BACKUP_INTERVAL} before next backup..."
        sleep "${BACKUP_INTERVAL}"
    done
else
    # Run once
    # Check if database is available before backup
    if pg_isready -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" 2>/dev/null; then
        main
    else
        warn "Database not ready, exiting..."
        exit 1
    fi
fi