#!/bin/bash
# SSL Certificate Setup Script for Odoo Production

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

# Configuration
DOMAIN="${DOMAIN_NAME:-your-domain.com}"
SSL_DIR="./nginx/ssl"
COUNTRY="TH"
STATE="Bangkok"
CITY="Bangkok"
ORG="Your Organization"
OU="IT Department"
EMAIL="admin@${DOMAIN}"

# Function to create self-signed certificate
create_self_signed() {
    log "Creating self-signed SSL certificate for ${DOMAIN}..."
    
    mkdir -p "${SSL_DIR}"
    
    # Generate private key
    openssl genrsa -out "${SSL_DIR}/odoo.key" 2048
    
    # Generate certificate signing request
    openssl req -new -key "${SSL_DIR}/odoo.key" -out "${SSL_DIR}/odoo.csr" -subj "/C=${COUNTRY}/ST=${STATE}/L=${CITY}/O=${ORG}/OU=${OU}/CN=${DOMAIN}/emailAddress=${EMAIL}"
    
    # Generate self-signed certificate
    openssl x509 -req -days 365 -in "${SSL_DIR}/odoo.csr" -signkey "${SSL_DIR}/odoo.key" -out "${SSL_DIR}/odoo.crt"
    
    # Set proper permissions
    chmod 600 "${SSL_DIR}/odoo.key"
    chmod 644 "${SSL_DIR}/odoo.crt"
    
    log "Self-signed certificate created successfully!"
    warn "This is a self-signed certificate. Browsers will show security warnings."
    warn "For production, consider using Let's Encrypt or a commercial certificate."
}

# Function to setup Let's Encrypt with Certbot
setup_letsencrypt() {
    log "Setting up Let's Encrypt certificate for ${DOMAIN}..."
    
    # Check if running on Linux
    if [[ "$OSTYPE" != "linux-gnu"* ]]; then
        error "Let's Encrypt setup requires Linux. Use self-signed certificate for Windows."
        return 1
    fi
    
    # Install certbot if not present
    if ! command -v certbot &> /dev/null; then
        log "Installing certbot..."
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y certbot
        elif command -v yum &> /dev/null; then
            sudo yum install -y certbot
        else
            error "Package manager not supported. Please install certbot manually."
            return 1
        fi
    fi
    
    # Create webroot directory
    mkdir -p ./nginx/webroot
    
    # Generate certificate
    sudo certbot certonly --webroot \
        --webroot-path=./nginx/webroot \
        --email "${EMAIL}" \
        --agree-tos \
        --no-eff-email \
        -d "${DOMAIN}"
    
    # Copy certificates to nginx directory
    sudo cp "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "${SSL_DIR}/odoo.crt"
    sudo cp "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" "${SSL_DIR}/odoo.key"
    
    # Set proper permissions
    sudo chmod 644 "${SSL_DIR}/odoo.crt"
    sudo chmod 600 "${SSL_DIR}/odoo.key"
    sudo chown $(whoami):$(whoami) "${SSL_DIR}"/*
    
    log "Let's Encrypt certificate installed successfully!"
    
    # Setup auto-renewal
    cat > ./scripts/ssl-renew.sh << 'EOF'
#!/bin/bash
# Auto-renewal script for Let's Encrypt certificates

DOMAIN="${DOMAIN_NAME:-your-domain.com}"
SSL_DIR="./nginx/ssl"

# Renew certificate
sudo certbot renew --quiet

# Copy renewed certificates
if sudo test -f "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"; then
    sudo cp "/etc/letsencrypt/live/${DOMAIN}/fullchain.pem" "${SSL_DIR}/odoo.crt"
    sudo cp "/etc/letsencrypt/live/${DOMAIN}/privkey.pem" "${SSL_DIR}/odoo.key"
    sudo chown $(whoami):$(whoami) "${SSL_DIR}"/*
    
    # Reload nginx
    docker-compose -f docker-compose.prod.yml exec nginx nginx -s reload
    
    echo "Certificate renewed and nginx reloaded"
fi
EOF
    
    chmod +x ./scripts/ssl-renew.sh
    
    log "Auto-renewal script created at ./scripts/ssl-renew.sh"
    log "Add to crontab: 0 3 * * * /path/to/ssl-renew.sh"
}

# Main function
main() {
    echo "SSL Certificate Setup for Odoo Production"
    echo "========================================"
    echo "Domain: ${DOMAIN}"
    echo ""
    echo "Choose certificate type:"
    echo "1) Self-signed certificate (works on Windows/Linux)"
    echo "2) Let's Encrypt certificate (Linux only, requires public domain)"
    echo ""
    read -p "Enter your choice [1-2]: " choice
    
    case $choice in
        1)
            create_self_signed
            ;;
        2)
            setup_letsencrypt
            ;;
        *)
            error "Invalid choice. Defaulting to self-signed certificate."
            create_self_signed
            ;;
    esac
    
    echo ""
    log "SSL setup completed!"
    log "Certificate location: ${SSL_DIR}/odoo.crt"
    log "Private key location: ${SSL_DIR}/odoo.key"
    log ""
    log "Next steps:"
    log "1. Update your .env.prod file with the correct DOMAIN_NAME"
    log "2. Update nginx/nginx.conf with your domain name"
    log "3. Start the production environment with: docker-compose -f docker-compose.prod.yml up -d"
}

# Check if domain is provided
if [[ -z "${DOMAIN_NAME}" ]]; then
    warn "DOMAIN_NAME not set in environment. Using default: your-domain.com"
    warn "Set DOMAIN_NAME=your-actual-domain.com before running this script"
fi

# Create scripts directory
mkdir -p ./scripts

# Run main function
main "$@"