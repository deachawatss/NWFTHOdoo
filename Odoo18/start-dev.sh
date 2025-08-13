#!/bin/bash

# Odoo 18 Development Environment Starter
# Based on best practices for Odoo development environment setup

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Project paths
PROJECT_DIR="/home/deachawat/dev/projects/Odoo/Odoo18"
CONFIG_FILE="$PROJECT_DIR/odoo-dev.conf"
LOG_DIR="$PROJECT_DIR/logs"
VENV_DIR="$PROJECT_DIR/venv"

# Logging function
log() {
    echo -e "${BLUE}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if PostgreSQL is running
check_postgresql() {
    log "Checking PostgreSQL service status..."
    if ! pgrep -x postgres >/dev/null 2>&1; then
        error "PostgreSQL is not running. Please start it first:"
        echo "  sudo service postgresql start"
        exit 1
    fi
    success "PostgreSQL is running"
}

# Function to check database connection
check_database_connection() {
    log "Testing database connection..."
    export PGPASSWORD=1234
    if psql -h localhost -p 5432 -U admin -d postgres -c "SELECT version();" >/dev/null 2>&1; then
        success "Database connection successful"
    else
        error "Failed to connect to PostgreSQL with admin/1234"
        echo "Please ensure PostgreSQL is configured with:"
        echo "  User: admin"
        echo "  Password: 1234"
        echo "  Or update the credentials in odoo-dev.conf"
        exit 1
    fi
}

# Function to create virtual environment if it doesn't exist
setup_virtualenv() {
    if [ ! -d "$VENV_DIR" ]; then
        log "Creating Python virtual environment..."
        python3 -m venv "$VENV_DIR"
        success "Virtual environment created at $VENV_DIR"
        
        # Upgrade pip in new environment
        source "$VENV_DIR/bin/activate"
        pip install --upgrade pip --quiet
    fi
    
    log "Activating virtual environment..."
    source "$VENV_DIR/bin/activate"
    
    # Check if requirements need to be installed
    log "Checking Python dependencies..."
    if ! pip show babel >/dev/null 2>&1; then
        warning "Python dependencies not found, installing from requirements.txt..."
        
        # Try to install core dependencies first
        log "Installing core dependencies..."
        pip install psycopg2-binary lxml-html-clean babel pytz werkzeug passlib \
                   pillow reportlab jinja2 markupsafe pypdf2 python-dateutil \
                   openpyxl xlwt xlrd num2words polib qrcode zeep xlsxwriter \
                   vobject freezegun idna chardet decorator --quiet
        
        # Try to install full requirements
        log "Installing remaining dependencies from requirements.txt..."
        if ! pip install -r "$PROJECT_DIR/requirements.txt" --quiet; then
            warning "Some dependencies failed to install from requirements.txt"
            warning "Please ensure system dependencies are installed (see DEV_SETUP.md)"
            log "Continuing with currently installed packages..."
        fi
        success "Python dependencies installation completed"
    else
        log "Python dependencies are already installed"
    fi
}

# Function to create log directory
setup_logs() {
    if [ ! -d "$LOG_DIR" ]; then
        mkdir -p "$LOG_DIR"
        log "Created log directory: $LOG_DIR"
    fi
}

# Function to check config file
check_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        error "Configuration file not found: $CONFIG_FILE"
        echo "Please ensure odoo-dev.conf exists in the project directory."
        exit 1
    fi
    success "Configuration file found: $CONFIG_FILE"
}

# Function to display startup information
display_info() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}Odoo 18 Development Server${NC}"
    echo "=========================================="
    echo "Project Directory: $PROJECT_DIR"
    echo "Configuration: $CONFIG_FILE"
    echo "Log Directory: $LOG_DIR"
    echo "Virtual Environment: $VENV_DIR"
    echo ""
    echo "Database Configuration:"
    echo "  Host: localhost"
    echo "  Port: 5432"
    echo "  User: admin"
    echo "  Password: 1234"
    echo ""
    echo "Server will be available at:"
    echo "  🌐 Web Interface: http://localhost:8069"
    echo "  🔧 Admin Interface: http://localhost:8069/web/database/manager"
    echo ""
    echo -e "${YELLOW}Note: Database selection will be available in the web interface${NC}"
    echo "=========================================="
    echo ""
}

# Main execution
main() {
    log "Starting Odoo 18 development environment..."
    
    # Change to project directory
    cd "$PROJECT_DIR" || {
        error "Failed to change to project directory: $PROJECT_DIR"
        exit 1
    }
    
    # Run all checks and setup
    check_postgresql
    check_database_connection
    check_config
    setup_logs
    setup_virtualenv
    
    # Display information
    display_info
    
    # Start Odoo
    log "Starting Odoo server..."
    echo -e "${GREEN}Press Ctrl+C to stop the server${NC}"
    echo ""
    
    # Activate virtual environment and start Odoo
    source "$VENV_DIR/bin/activate"
    
    # Start Odoo with comprehensive options
    python3 ./odoo-bin \
        --config="$CONFIG_FILE" \
        --dev=all \
        --log-level=info \
        --log-handler=:INFO \
        --logfile="$LOG_DIR/odoo-$(date +%Y%m%d-%H%M%S).log" \
        --workers=0 \
        --max-cron-threads=1 \
        --without-demo=without \
        --db-filter=.* \
        "$@"
}

# Trap Ctrl+C for graceful shutdown
trap 'echo -e "\n${YELLOW}Shutting down Odoo development server...${NC}"; exit 0' INT

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi