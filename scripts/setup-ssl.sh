#!/bin/bash

# SSL Certificate Setup Script for Valera Production
# Supports Let's Encrypt with automatic renewal

set -euo pipefail

# Configuration
DOMAIN="valera.yourdomain.com"
EMAIL="admin@yourdomain.com"
SSL_DIR="/etc/nginx/ssl"
CERTBOT_DIR="/etc/letsencrypt"
DOCKER_COMPOSE_FILE="docker-compose.production.yml"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check if running as root
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root for SSL certificate setup"
    fi

    # Check if domain is set
    if [[ "$DOMAIN" == "valera.yourdomain.com" ]]; then
        error "Please update the DOMAIN variable in this script before running"
    fi

    # Check if nginx is installed
    if ! command -v nginx &> /dev/null; then
        error "nginx is not installed. Please install nginx first."
    fi

    # Check if certbot is installed
    if ! command -v certbot &> /dev/null; then
        log "Installing certbot..."
        apt-get update
        apt-get install -y certbot python3-certbot-nginx
    fi

    success "Prerequisites check completed"
}

# Create SSL directory structure
create_ssl_directories() {
    log "Creating SSL directory structure..."

    mkdir -p "$SSL_DIR"
    mkdir -p "$CERTBOT_DIR"

    # Set appropriate permissions
    chmod 755 "$SSL_DIR"
    chmod 755 "$CERTBOT_DIR"

    success "SSL directories created"
}

# Generate self-signed certificate for testing
generate_self_signed_cert() {
    log "Generating self-signed certificate for testing..."

    if [[ -f "$SSL_DIR/cert.pem" && -f "$SSL_DIR/key.pem" ]]; then
        warning "SSL certificates already exist. Skipping self-signed certificate generation."
        return 0
    fi

    # Generate private key
    openssl genrsa -out "$SSL_DIR/key.pem" 2048

    # Generate certificate signing request
    openssl req -new -key "$SSL_DIR/key.pem" -out "$SSL_DIR/csr.pem" -subj "/C=RU/ST=Moscow/L=Moscow/O=Valera/OU=IT/CN=$DOMAIN"

    # Generate self-signed certificate (valid for 365 days)
    openssl x509 -req -days 365 -in "$SSL_DIR/csr.pem" -signkey "$SSL_DIR/key.pem" -out "$SSL_DIR/cert.pem"

    # Create full chain file (self-signed case)
    cp "$SSL_DIR/cert.pem" "$SSL_DIR/chain.pem"

    # Set appropriate permissions
    chmod 600 "$SSL_DIR/key.pem"
    chmod 644 "$SSL_DIR/cert.pem"
    chmod 644 "$SSL_DIR/chain.pem"
    chmod 644 "$SSL_DIR/csr.pem"

    success "Self-signed certificate generated"
}

# Setup Let's Encrypt certificate
setup_letsencrypt() {
    log "Setting up Let's Encrypt certificate for $DOMAIN..."

    # Check if domain resolves to this server
    if ! dig +short "$DOMAIN" | grep -q "$(curl -s ifconfig.me)"; then
        warning "Domain $DOMAIN does not resolve to this server's IP address."
        warning "Let's Encrypt certificate generation may fail."
        read -p "Do you want to continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Skipping Let's Encrypt certificate setup"
            return 0
        fi
    fi

    # Stop nginx to free up port 80
    if docker-compose -f "$DOCKER_COMPOSE_FILE" ps nginx | grep -q "Up"; then
        log "Stopping nginx for Let's Encrypt validation..."
        docker-compose -f "$DOCKER_COMPOSE_FILE" stop nginx
    fi

    # Request certificate from Let's Encrypt
    if certbot certonly --standalone --email "$EMAIL" --agree-tos --no-eff-email -d "$DOMAIN"; then
        success "Let's Encrypt certificate obtained successfully"

        # Copy certificates to nginx SSL directory
        cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/cert.pem"
        cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/key.pem"
        cp "/etc/letsencrypt/live/$DOMAIN/chain.pem" "$SSL_DIR/chain.pem"

        # Set appropriate permissions
        chmod 600 "$SSL_DIR/key.pem"
        chmod 644 "$SSL_DIR/cert.pem"
        chmod 644 "$SSL_DIR/chain.pem"

        # Setup automatic renewal
        setup_renewal
    else
        error "Failed to obtain Let's Encrypt certificate"
    fi

    # Restart nginx
    log "Restarting nginx..."
    docker-compose -f "$DOCKER_COMPOSE_FILE" start nginx
}

# Setup automatic renewal
setup_renewal() {
    log "Setting up automatic certificate renewal..."

    # Create renewal script
    cat > /usr/local/bin/renew-ssl.sh << 'EOF'
#!/bin/bash
# SSL Certificate Renewal Script

DOMAIN="valera.yourdomain.com"
SSL_DIR="/etc/nginx/ssl"
DOCKER_COMPOSE_FILE="docker-compose.production.yml"

# Renew certificate
if certbot renew --quiet; then
    echo "Certificate renewed successfully"

    # Copy new certificates
    cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "$SSL_DIR/cert.pem"
    cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "$SSL_DIR/key.pem"
    cp "/etc/letsencrypt/live/$DOMAIN/chain.pem" "$SSL_DIR/chain.pem"

    # Reload nginx
    docker-compose -f "$DOCKER_COMPOSE_FILE" exec nginx nginx -s reload
    echo "Nginx reloaded with new certificates"
else
    echo "Certificate renewal not needed or failed"
fi
EOF

    chmod +x /usr/local/bin/renew-ssl.sh

    # Add cron job for renewal (check twice daily)
    (crontab -l 2>/dev/null; echo "0 0,12 * * * /usr/local/bin/renew-ssl.sh >> /var/log/ssl-renewal.log 2>&1") | crontab -

    success "Automatic renewal setup completed"
}

# Test SSL configuration
test_ssl_config() {
    log "Testing SSL configuration..."

    # Test nginx configuration
    if docker-compose -f "$DOCKER_COMPOSE_FILE" exec nginx nginx -t; then
        success "Nginx SSL configuration is valid"
    else
        error "Nginx SSL configuration is invalid"
    fi

    # Test SSL certificate
    if openssl x509 -in "$SSL_DIR/cert.pem" -text -noout > /dev/null 2>&1; then
        success "SSL certificate is valid"

        # Show certificate details
        log "Certificate details:"
        openssl x509 -in "$SSL_DIR/cert.pem" -text -noout | grep -E "(Subject:|Issuer:|Not Before:|Not After:)" || true
    else
        error "SSL certificate is invalid"
    fi
}

# SSL security hardening
ssl_hardening() {
    log "Applying SSL security hardening..."

    # Create strong Diffie-Hellman parameters
    if [[ ! -f "$SSL_DIR/dhparam.pem" ]]; then
        log "Generating Diffie-Hellman parameters (this may take a few minutes)..."
        openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048
        chmod 600 "$SSL_DIR/dhparam.pem"
        success "Diffie-Hellman parameters generated"
    else
        log "Diffie-Hellman parameters already exist"
    fi

    # Test SSL configuration with SSL Labs
    log "You can test your SSL configuration at: https://www.ssllabs.com/ssltest/"
    log "Enter your domain: $DOMAIN"
}

# Main function
main() {
    log "Starting SSL certificate setup for Valera"

    case "${1:-selfsigned}" in
        "selfsigned")
            check_prerequisites
            create_ssl_directories
            generate_self_signed_cert
            test_ssl_config
            ssl_hardening
            success "Self-signed SSL certificate setup completed"
            ;;
        "letsencrypt")
            check_prerequisites
            create_ssl_directories
            setup_letsencrypt
            test_ssl_config
            ssl_hardening
            success "Let's Encrypt SSL certificate setup completed"
            ;;
        "test")
            test_ssl_config
            ;;
        *)
            echo "Usage: $0 [selfsigned|letsencrypt|test]"
            echo "  selfsigned  - Generate self-signed certificate for testing"
            echo "  letsencrypt - Setup Let's Encrypt certificate for production"
            echo "  test       - Test existing SSL configuration"
            exit 1
            ;;
    esac

    echo
    echo "=== Next Steps ==="
    echo "1. Update DOMAIN and EMAIL variables in this script"
    echo "2. Update server_name in nginx.conf to match your domain"
    echo "3. Test SSL configuration: curl -I https://$DOMAIN"
    echo "4. Monitor SSL renewal logs: tail -f /var/log/ssl-renewal.log"
    echo "5. Check SSL security: https://www.ssllabs.com/ssltest/"
}

# Run main function
main "$@"