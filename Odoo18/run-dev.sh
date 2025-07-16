#!/bin/bash

# Odoo 18 Development Server Script
# Similar to 'npm run dev' for easy development with hot reloading

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"
}

# Function to show usage
show_usage() {
    echo -e "${CYAN}Odoo 18 Development Server${NC}"
    echo ""
    echo -e "${YELLOW}Usage:${NC}"
    echo "  ./run-dev.sh <database_name> [options]"
    echo ""
    echo -e "${YELLOW}Examples:${NC}"
    echo "  ./run-dev.sh mydb               # Use 'mydb' database"
    echo "  ./run-dev.sh mydb --update-all  # Update all modules on startup"
    echo "  ./run-dev.sh mydb -i base       # Install base module"
    echo "  ./run-dev.sh test_db            # Use 'test_db' database"
    echo ""
    echo -e "${YELLOW}Features:${NC}"
    echo "  - Auto-reload on file changes"
    echo "  - Hot reloading for Python, XML, QWeb templates"
    echo "  - Development-friendly logging"
    echo "  - Automatic addon path detection"
    echo ""
}

# Function to detect addon paths
detect_addon_paths() {
    local paths=""
    
    # Standard addons directory
    if [ -d "addons" ]; then
        paths="addons"
    fi
    
    # Custom addons directory
    if [ -d "custom_addons" ]; then
        if [ -n "$paths" ]; then
            paths="$paths,custom_addons"
        else
            paths="custom_addons"
        fi
    fi
    
    # Enterprise addons (if exists)
    if [ -d "enterprise" ]; then
        if [ -n "$paths" ]; then
            paths="$paths,enterprise"
        else
            paths="enterprise"
        fi
    fi
    
    # Additional addon directories
    for dir in addons-*/ */addons/; do
        if [ -d "$dir" ] && [[ "$dir" != "addons/" ]]; then
            dir=${dir%/}  # Remove trailing slash
            if [ -n "$paths" ]; then
                paths="$paths,$dir"
            else
                paths="$dir"
            fi
        fi
    done
    
    echo "$paths"
}

# Function to check if database exists
check_database() {
    local db_name="$1"
    
    if command -v psql >/dev/null 2>&1; then
        if psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$db_name"; then
            return 0
        fi
    fi
    return 1
}

# Function to suggest database name
suggest_database() {
    # Try to find existing databases that might be Odoo databases
    if command -v psql >/dev/null 2>&1; then
        local existing_dbs=$(psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -E "(odoo|dev)" | head -1 | xargs)
        if [ -n "$existing_dbs" ]; then
            echo "$existing_dbs"
            return 0
        fi
    fi
    
    # No suitable database found
    return 1
}

# Main function
main() {
    # Check if help is requested
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi
    
    log "Starting Odoo 18 Development Server..."
    
    # Check if odoo-bin exists
    if [ ! -f "odoo-bin" ]; then
        error "odoo-bin not found! Please run this script from the Odoo root directory."
    fi
    
    # Detect addon paths
    local addon_paths=$(detect_addon_paths)
    if [ -z "$addon_paths" ]; then
        warn "No addon directories found, using default paths"
        addon_paths="addons"
    fi
    info "Addon paths: $addon_paths"
    
    # Determine database name
    local database_name=""
    local extra_args=()
    
    # Parse arguments
    if [ $# -eq 0 ]; then
        # No arguments, try to suggest database or show help
        if database_name=$(suggest_database); then
            warn "No database specified, using existing database: $database_name"
            info "Next time, specify database explicitly: ./run-dev.sh $database_name"
        else
            error "No database specified and no existing Odoo databases found.
Please specify a database name:
  ./run-dev.sh <database_name>

Or use --help for more information:
  ./run-dev.sh --help"
        fi
    else
        # First argument should be database name
        database_name="$1"
        shift
        
        # Rest are extra arguments
        extra_args=("$@")
    fi
    
    # Check if database exists
    if ! check_database "$database_name"; then
        warn "Database '$database_name' may not exist"
        info "Odoo will create it if needed, or you can create it manually:"
        info "  createdb $database_name"
    else
        log "Database '$database_name' found"
    fi
    
    # Build the command
    local cmd=(
        python3 odoo-bin
        --database="$database_name"
        --addons-path="$addon_paths"
        --dev=reload,qweb,werkzeug,xml
        --log-level=info
        --http-port=8069
        --gevent-port=8072
    )
    
    # Add extra arguments
    if [ ${#extra_args[@]} -gt 0 ]; then
        cmd+=("${extra_args[@]}")
        info "Extra arguments: ${extra_args[*]}"
    fi
    
    # Show what we're about to run
    info "Starting Odoo with command:"
    echo -e "${PURPLE}${cmd[*]}${NC}"
    echo ""
    
    # Start Odoo
    log "🚀 Odoo development server starting..."
    log "📱 Web interface: http://localhost:8069"
    log "🔄 Hot reloading enabled for Python, XML, and QWeb files"
    log "🛑 Press Ctrl+C to stop the server"
    echo ""
    
    # Execute the command
    exec "${cmd[@]}"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi