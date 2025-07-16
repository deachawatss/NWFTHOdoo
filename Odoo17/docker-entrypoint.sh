#!/bin/bash
set -e

# Default database settings
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='odoo'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='odoo123'}}}
: ${POSTGRES_DB:=${DB_ENV_POSTGRES_DB:=${POSTGRES_DB:='odoo'}}}

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

# Function to wait for database
wait_for_db() {
    log "Waiting for database to be ready..."
    while ! pg_isready -h "$HOST" -p "$PORT" -U "$USER" 2>/dev/null; do
        sleep 1
    done
    log "Database is ready!"
}

# Function to check if database exists
db_exists() {
    psql -h "$HOST" -p "$PORT" -U "$USER" -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"
}

# Function to create database if it doesn't exist
create_db_if_not_exists() {
    if ! db_exists; then
        log "Database '$POSTGRES_DB' does not exist. Creating..."
        createdb -h "$HOST" -p "$PORT" -U "$USER" "$POSTGRES_DB" 2>/dev/null || true
        log "Database '$POSTGRES_DB' created successfully!"
    else
        log "Database '$POSTGRES_DB' already exists."
    fi
}

# Function to update configuration
update_config() {
    log "Updating Odoo configuration..."
    
    # Create odoo.conf if it doesn't exist
    if [ ! -f /opt/odoo/odoo.conf ]; then
        log "Creating odoo.conf file..."
        cat > /opt/odoo/odoo.conf << EOF
[options]
admin_passwd = admin
db_host = $HOST
db_port = $PORT
db_user = $USER
db_password = $PASSWORD
http_port = 8069
gevent_port = 8072
addons_path = /opt/odoo/addons,/opt/odoo/custom_addons
data_dir = /var/lib/odoo
logfile = /var/log/odoo/odoo.log
log_level = info
logrotate = True
EOF
        log "Configuration file created"
    fi
}

# Function to set permissions
set_permissions() {
    log "Setting up permissions..."
    if [ "$(id -u)" = "0" ]; then
        chown -R odoo:odoo /var/lib/odoo /var/log/odoo 2>/dev/null || true
        chmod -R 755 /var/lib/odoo /var/log/odoo 2>/dev/null || true
    fi
}

# Main execution
main() {
    log "Starting Odoo 17 Docker container..."
    
    # Export database connection variables
    export PGPASSWORD="$PASSWORD"
    
    # Wait for database
    wait_for_db
    
    # Create database if needed
    create_db_if_not_exists
    
    # Update configuration
    update_config
    
    # Set permissions
    set_permissions
    
    # Handle special cases
    case "$1" in
        odoo)
            log "Starting Odoo server..."
            exec python3 /opt/odoo/odoo-bin -c /opt/odoo/odoo.conf
            ;;
        shell)
            log "Starting interactive shell..."
            exec /bin/bash
            ;;
        *)
            log "Executing: $@"
            exec "$@"
            ;;
    esac
}

# Check if running as root and switch to odoo user if needed
if [ "$(id -u)" = "0" ]; then
    warn "Running as root, switching to odoo user..."
    set_permissions
    exec gosu odoo "$0" "$@"
fi

# Run main function
main "$@"