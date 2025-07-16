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
    while ! pg_isready -h "$HOST" -p "$PORT" -U "$USER"; do
        sleep 1
    done
    log "Database is ready!"
}

# Function to check if database exists
db_exists() {
    psql -h "$HOST" -p "$PORT" -U "$USER" -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"
}

# Function to create database if it doesn't exist
create_db_if_not_exists() {
    if ! db_exists; then
        log "Database '$POSTGRES_DB' does not exist. Creating..."
        createdb -h "$HOST" -p "$PORT" -U "$USER" "$POSTGRES_DB"
        log "Database '$POSTGRES_DB' created successfully!"
    else
        log "Database '$POSTGRES_DB' already exists."
    fi
}

# Function to initialize Odoo database
init_db() {
    if [ "$1" = "odoo" ]; then
        log "Initializing Odoo database..."
        set -- "$@" --init=base --database="$POSTGRES_DB" --without-demo=False
        log "Database initialization parameters added"
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
xmlrpc_port = 8069
longpolling_port = 8072
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
    chown -R odoo:odoo /var/lib/odoo /var/log/odoo
    chmod -R 755 /var/lib/odoo /var/log/odoo
}

# Function to run database migrations
run_migrations() {
    if [ "$1" = "odoo" ] && [ -n "$ODOO_MIGRATE" ]; then
        log "Running database migrations..."
        set -- "$@" --update=all --database="$POSTGRES_DB"
        log "Migration parameters added"
    fi
}

# Function to install demo data
install_demo_data() {
    if [ "$1" = "odoo" ] && [ "$ODOO_DEMO" = "True" ]; then
        log "Installing demo data..."
        set -- "$@" --without-demo=False
        log "Demo data installation enabled"
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
            # Initialize database if needed
            if [ "$ODOO_INIT_DB" = "True" ]; then
                init_db "$@"
            fi
            
            # Run migrations if needed
            run_migrations "$@"
            
            # Install demo data if needed
            install_demo_data "$@"
            
            log "Starting Odoo server..."
            exec python3 /opt/odoo/odoo-bin "$@"
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