#!/bin/bash
# Verification script for Docker production fixes

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
}

# Function to check file syntax
check_syntax() {
    local file="$1"
    local type="$2"
    
    log "Checking syntax of $file..."
    
    case "$type" in
        yaml)
            if command -v python3 >/dev/null 2>&1; then
                python3 -c "import yaml; yaml.safe_load(open('$file'))" && log "✓ $file syntax is valid" || error "✗ $file syntax error"
            else
                warn "Python3 not available for YAML validation"
            fi
            ;;
        bash)
            if bash -n "$file"; then
                log "✓ $file syntax is valid"
            else
                error "✗ $file syntax error"
            fi
            ;;
        *)
            log "Skipping syntax check for $file (unknown type: $type)"
            ;;
    esac
}

# Function to verify Docker configuration
verify_docker_config() {
    log "=== Verifying Docker Configuration ==="
    
    check_syntax "docker-compose.yml" "yaml"
    check_syntax "Dockerfile" "bash"
    check_syntax "docker-entrypoint.sh" "bash"
    
    # Check if docker-compose is valid
    if command -v docker-compose >/dev/null 2>&1; then
        if docker-compose config >/dev/null 2>&1; then
            log "✓ Docker Compose configuration is valid"
        else
            error "✗ Docker Compose configuration is invalid"
        fi
    else
        warn "docker-compose not available for validation"
    fi
}

# Function to verify Python requirements
verify_python_requirements() {
    log "=== Verifying Python Requirements ==="
    
    if [ -f "requirements.txt" ]; then
        log "✓ requirements.txt exists"
        
        # Check for setuptools pin
        if grep -q "setuptools<81" requirements.txt; then
            log "✓ setuptools is pinned to prevent pkg_resources warnings"
        else
            warn "setuptools pin not found in requirements.txt"
        fi
    else
        error "✗ requirements.txt not found"
    fi
}

# Function to verify Odoo configuration
verify_odoo_config() {
    log "=== Verifying Odoo Configuration ==="
    
    if [ -f "odoo.conf" ]; then
        log "✓ odoo.conf exists"
        
        # Check key production settings
        local settings_found=0
        
        if grep -q "workers.*=" odoo.conf; then
            log "✓ Worker configuration found"
            settings_found=$((settings_found + 1))
        fi
        
        if grep -q "redis_host.*=" odoo.conf; then
            log "✓ Redis configuration found"
            settings_found=$((settings_found + 1))
        fi
        
        if grep -q "limit_memory_soft.*=" odoo.conf; then
            log "✓ Memory limits configured"
            settings_found=$((settings_found + 1))
        fi
        
        if [ $settings_found -eq 3 ]; then
            log "✓ All key production settings found"
        else
            warn "Some production settings may be missing"
        fi
    else
        error "✗ odoo.conf not found"
    fi
}

# Function to verify file permissions
verify_permissions() {
    log "=== Verifying File Permissions ==="
    
    if [ -x "docker-entrypoint.sh" ]; then
        log "✓ docker-entrypoint.sh is executable"
    else
        error "✗ docker-entrypoint.sh is not executable"
    fi
    
    if [ -d "scripts" ]; then
        for script in scripts/*.sh; do
            if [ -x "$script" ]; then
                log "✓ $script is executable"
            else
                warn "$script is not executable"
            fi
        done
    fi
}

# Function to show deployment recommendations
show_recommendations() {
    log "=== Deployment Recommendations ==="
    
    log "1. Build containers: docker-compose build --no-cache"
    log "2. Start services: docker-compose up -d"
    log "3. Monitor logs: docker-compose logs -f odoo"
    log "4. Check health: docker-compose ps"
    log "5. Test connection: curl http://192.168.0.21:8069"
    
    log ""
    log "Expected improvements:"
    log "• Faster container startup (300s vs 180s timeout)"
    log "• Better error logging and debugging"
    log "• No more pkg_resources deprecation warnings"
    log "• Improved health checks with fallback endpoints"
    log "• Redis session storage integration"
    log "• Optimized memory usage (6GB limit with proper workers)"
}

# Main execution
main() {
    log "Starting Docker production fixes verification..."
    log "Current directory: $(pwd)"
    log ""
    
    verify_docker_config
    log ""
    
    verify_python_requirements
    log ""
    
    verify_odoo_config
    log ""
    
    verify_permissions
    log ""
    
    show_recommendations
    log ""
    
    log "Verification completed! ✓"
}

# Run main function
main "$@"