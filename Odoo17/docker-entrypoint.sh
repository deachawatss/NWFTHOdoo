#!/bin/bash
set -e

# Default database settings (production values)
: ${HOST:=${DB_PORT_5432_TCP_ADDR:='db'}}
: ${PORT:=${DB_PORT_5432_TCP_PORT:=5432}}
: ${USER:=${DB_ENV_POSTGRES_USER:=${POSTGRES_USER:='admin'}}}
: ${PASSWORD:=${DB_ENV_POSTGRES_PASSWORD:=${POSTGRES_PASSWORD:='1234'}}}
: ${POSTGRES_DB:=${DB_ENV_POSTGRES_DB:=${POSTGRES_DB:='odoo_admin'}}}

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
    local retries=0
    local max_retries=60
    
    while ! pg_isready -h "$HOST" -p "$PORT" -U "$USER" 2>/dev/null; do
        retries=$((retries + 1))
        if [ $retries -gt $max_retries ]; then
            error "Database connection timeout after $max_retries attempts"
            exit 1
        fi
        log "Database not ready, attempt $retries/$max_retries..."
        sleep 2
    done
    log "Database is ready!"
}

# Function to check if database exists
db_exists() {
    psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"
}

# Function to create database if it doesn't exist
create_db_if_not_exists() {
    log "Checking and creating required databases..."
    
    # Create database with same name as user (PostgreSQL convention)
    local user_db="$USER"
    log "Checking if database '$user_db' exists..."
    if ! psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$user_db"; then
        log "Database '$user_db' does not exist. Creating..."
        if createdb -h "$HOST" -p "$PORT" -U "$USER" -d postgres "$user_db" 2>/dev/null; then
            log "Database '$user_db' created successfully!"
        else
            # Try alternative method using SQL
            log "Trying alternative database creation method..."
            psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -c "CREATE DATABASE \"$user_db\";" 2>/dev/null || warn "Could not create database '$user_db'"
        fi
    else
        log "Database '$user_db' already exists."
    fi
    
    # Ensure main postgres database exists (should exist by default)
    if ! db_exists; then
        log "Database '$POSTGRES_DB' does not exist. Creating..."
        if createdb -h "$HOST" -p "$PORT" -U "$USER" -d postgres "$POSTGRES_DB" 2>/dev/null; then
            log "Database '$POSTGRES_DB' created successfully!"
        else
            # Try alternative method using SQL
            log "Trying alternative database creation method for '$POSTGRES_DB'..."
            psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -c "CREATE DATABASE \"$POSTGRES_DB\";" 2>/dev/null || warn "Could not create database '$POSTGRES_DB'"
        fi
    else
        log "Database '$POSTGRES_DB' already exists."
    fi
    
    # List available databases for verification
    log "Available databases:"
    psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -l 2>/dev/null || warn "Could not list databases"
}

# Function to update configuration (only if not already configured)
update_config() {
    # Check if configuration has already been updated to prevent loops
    if [ -f /tmp/odoo_config_updated ]; then
        log "Configuration already updated, skipping..."
        return 0
    fi
    
    log "Updating Odoo configuration..."
    
    # Only update database connection settings if file is writable and not already updated
    if [ -f /opt/odoo/odoo.conf ] && [ -w /opt/odoo/odoo.conf ]; then
        log "Updating existing odoo.conf with production credentials..."
        
        # Update database connection settings only if they differ
        sed -i "s/^db_host = .*/db_host = $HOST/" /opt/odoo/odoo.conf
        sed -i "s/^db_port = .*/db_port = $PORT/" /opt/odoo/odoo.conf
        sed -i "s/^db_user = .*/db_user = $USER/" /opt/odoo/odoo.conf
        sed -i "s/^db_password = .*/db_password = $PASSWORD/" /opt/odoo/odoo.conf
        
        log "Database connection settings updated"
    elif [ ! -f /opt/odoo/odoo.conf ]; then
        log "Creating new odoo.conf file..."
        cat > /opt/odoo/odoo.conf << EOF
[options]
admin_passwd = 1234
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
    
    # Mark configuration as updated
    touch /tmp/odoo_config_updated
    
    # Display current database configuration (without password)
    log "Database connection settings:"
    log "  Host: $HOST"
    log "  Port: $PORT" 
    log "  User: $USER"
    log "  Database: $POSTGRES_DB"
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
            log "Checking Odoo configuration..."
            if [ ! -f /opt/odoo/odoo.conf ]; then
                error "Odoo configuration file not found at /opt/odoo/odoo.conf"
                exit 1
            fi
            
            # Check if this is a fresh start (no existing sessions)
            log "Preparing Odoo startup environment..."
            
            # Wait a bit to ensure database is fully ready
            log "Waiting 15 seconds for database stabilization..."
            sleep 15
            
            # Verify database connection and tables access
            log "Verifying database accessibility..."
            local retries=0
            local max_retries=10
            
            while ! psql -h "$HOST" -p "$PORT" -U "$USER" -d postgres -c "SELECT version();" >/dev/null 2>&1; do
                retries=$((retries + 1))
                if [ $retries -gt $max_retries ]; then
                    error "Database verification failed after $max_retries attempts"
                    exit 1
                fi
                log "Database not fully ready, verification attempt $retries/$max_retries..."
                sleep 3
            done
            
            log "Database verification successful!"
            
            log "Configuration file found, starting Odoo..."
            log "Using Python: $(python3 --version)"
            log "Using Odoo binary: /opt/odoo/odoo-bin"
            log "Server will be available at http://localhost:8069 after initialization"
            log "This may take 5-10 minutes for full startup..."
            
            # Export environment variables for Python warnings suppression
            export PYTHONWARNINGS="${PYTHONWARNINGS:-ignore::DeprecationWarning:pkg_resources}"
            export SETUPTOOLS_USE_DISTUTILS="${SETUPTOOLS_USE_DISTUTILS:-stdlib}"
            
            exec python3 /opt/odoo/odoo-bin -c /opt/odoo/odoo.conf --log-level=info --without-demo=all
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
    # Mark that we're switching users to prevent infinite loop
    export SWITCHED_TO_ODOO_USER=1
    exec gosu odoo "$0" "$@"
elif [ "$SWITCHED_TO_ODOO_USER" = "1" ]; then
    # Already switched to odoo user, don't switch again
    log "Running as odoo user, proceeding with startup..."
fi

# Run main function
main "$@"