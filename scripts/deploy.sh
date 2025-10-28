#!/bin/bash

# Production Deployment Script for Valera
# This script handles zero-downtime deployment with rollback capability

set -euo pipefail

# Configuration
PROJECT_NAME="valera"
BACKUP_DIR="/tmp/backups"
LOG_FILE="/var/log/deploy.log"
HEALTH_CHECK_TIMEOUT=300
ROLLBACK_ENABLED=true

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "$LOG_FILE"
}

# Pre-deployment checks
pre_deploy_checks() {
    log "Starting pre-deployment checks..."

    # Check if running as root (required for production deployment)
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root for production deployment"
    fi

    # Check Docker availability
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
    fi

    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed or not in PATH"
    fi

    # Check if .env.production file exists
    if [[ ! -f ".env.production" ]]; then
        error ".env.production file not found. Please create it before deployment."
    fi

    # Check available disk space (minimum 2GB)
    available_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $available_space -lt 2097152 ]]; then
        warning "Low disk space. At least 2GB recommended for deployment."
    fi

    # Check if port 80 and 443 are available
    if netstat -tuln | grep -q ":80 "; then
        warning "Port 80 is already in use. This might affect deployment."
    fi

    if netstat -tuln | grep -q ":443 "; then
        warning "Port 443 is already in use. This might affect deployment."
    fi

    # Check SSL certificates
    if [[ ! -d "config/nginx/ssl" ]]; then
        warning "SSL certificates directory not found. SSL configuration may be incomplete."
    fi

    success "Pre-deployment checks completed"
}

# Backup current deployment
backup_current_deployment() {
    log "Creating backup of current deployment..."

    mkdir -p "$BACKUP_DIR"
    backup_name="${PROJECT_NAME}_backup_$(date +%Y%m%d_%H%M%S)"
    backup_path="$BACKUP_DIR/$backup_name"

    # Backup database
    if docker-compose -f docker-compose.production.yml ps postgres | grep -q "Up"; then
        log "Backing up database..."
        docker-compose -f docker-compose.production.yml exec -T postgres pg_dump -U "$POSTGRES_USER" "$POSTGRES_DB" > "$backup_path/database.sql"

        # Compress database backup
        gzip "$backup_path/database.sql"
        log "Database backup completed and compressed"
    fi

    # Backup application files
    mkdir -p "$backup_path/app"
    cp -r app/ "$backup_path/app/" 2>/dev/null || warning "Could not backup app directory"
    cp -r config/ "$backup_path/config/" 2>/dev/null || warning "Could not backup config directory"
    cp -r db/ "$backup_path/db/" 2>/dev/null || warning "Could not backup db directory"

    # Store current git commit
    git rev-parse HEAD > "$backup_path/commit_hash"

    success "Backup created at $backup_path"
    echo "$backup_path" > "$BACKUP_DIR/last_backup"
}

# Health check function
health_check() {
    local url="$1"
    local timeout="$2"
    local attempts=0
    local max_attempts=30

    log "Performing health check on $url..."

    while [[ $attempts -lt $max_attempts ]]; do
        if curl -f -s -o /dev/null "$url"; then
            success "Health check passed"
            return 0
        fi

        attempts=$((attempts + 1))
        sleep 10
    done

    error "Health check failed after $((attempts * 10)) seconds"
}

# Deploy application
deploy_application() {
    log "Starting application deployment..."

    # Pull latest changes from git
    log "Fetching latest changes from repository..."
    git fetch origin
    git pull origin master

    # Build new Docker images
    log "Building Docker images..."
    docker-compose -f docker-compose.production.yml build --no-cache

    # Run database migrations
    log "Running database migrations..."
    docker-compose -f docker-compose.production.yml run --rm app rails db:migrate

    # Precompile assets
    log "Precompiling assets..."
    docker-compose -f docker-compose.production.yml run --rm app rails assets:precompile

    # Stop old containers (graceful shutdown)
    log "Stopping old containers..."
    docker-compose -f docker-compose.production.yml down

    # Start new containers
    log "Starting new containers..."
    docker-compose -f docker-compose.production.yml up -d

    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 30

    # Health checks
    health_check "http://localhost/health" "$HEALTH_CHECK_TIMEOUT"
    health_check "http://localhost/up" 60

    success "Application deployment completed"
}

# Rollback function
rollback() {
    if [[ "$ROLLBACK_ENABLED" != "true" ]]; then
        error "Rollback is disabled"
    fi

    if [[ ! -f "$BACKUP_DIR/last_backup" ]]; then
        error "No backup found for rollback"
    fi

    backup_path=$(cat "$BACKUP_DIR/last_backup")
    commit_hash=$(cat "$backup_path/commit_hash")

    log "Starting rollback to commit $commit_hash..."

    # Stop current containers
    docker-compose -f docker-compose.production.yml down

    # Restore database if backup exists
    if [[ -f "$backup_path/database.sql.gz" ]]; then
        log "Restoring database from backup..."
        gunzip -c "$backup_path/database.sql.gz" | docker-compose -f docker-compose.production.yml exec -T postgres psql -U "$POSTGRES_USER" "$POSTGRES_DB"
    fi

    # Checkout previous commit
    git checkout "$commit_hash"

    # Rebuild and start containers
    docker-compose -f docker-compose.production.yml build
    docker-compose -f docker-compose.production.yml up -d

    # Health check
    sleep 30
    health_check "http://localhost/health" "$HEALTH_CHECK_TIMEOUT"

    success "Rollback completed successfully"
}

# Cleanup old backups
cleanup_old_backups() {
    log "Cleaning up old backups (keeping last 7 days)..."

    find "$BACKUP_DIR" -name "${PROJECT_NAME}_backup_*" -type d -mtime +7 -exec rm -rf {} \;

    success "Old backups cleaned up"
}

# Post-deployment verification
post_deploy_verification() {
    log "Running post-deployment verification..."

    # Check if all containers are running
    containers=("valera_app" "valera_postgres" "valera_redis" "valera_nginx")

    for container in "${containers[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "^$container$"; then
            success "Container $container is running"
        else
            error "Container $container is not running"
        fi
    done

    # Test Telegram webhook
    if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]]; then
        log "Testing Telegram webhook..."
        webhook_response=$(curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getWebhookInfo")

        if echo "$webhook_response" | grep -q '"ok":true'; then
            success "Telegram webhook is configured correctly"
        else
            warning "Telegram webhook might need configuration"
        fi
    fi

    # Test database connectivity
    if docker-compose -f docker-compose.production.yml exec -T postgres pg_isready -U "$POSTGRES_USER" -d "$POSTGRES_DB" >/dev/null 2>&1; then
        success "Database is accessible"
    else
        error "Database is not accessible"
    fi

    # Check disk space after deployment
    final_space=$(df / | awk 'NR==2 {print $4}')
    if [[ $final_space -lt 1048576 ]]; then
        warning "Low disk space after deployment. Consider cleanup."
    fi

    success "Post-deployment verification completed"
}

# Main deployment function
main() {
    log "Starting production deployment for $PROJECT_NAME"

    # Check if rollback is requested
    if [[ "${1:-}" == "rollback" ]]; then
        rollback
        exit 0
    fi

    pre_deploy_checks
    backup_current_deployment
    deploy_application
    post_deploy_verification
    cleanup_old_backups

    success "Production deployment completed successfully!"
    log "Deployment log available at: $LOG_FILE"

    # Display next steps
    echo
    echo "=== Next Steps ==="
    echo "1. Monitor application logs: docker-compose -f docker-compose.production.yml logs -f app"
    echo "2. Check monitoring dashboard: http://localhost:3001 (Grafana)"
    echo "3. Configure SSL certificates if not already done"
    echo "4. Set up monitoring alerts"
    echo "5. To rollback: $0 rollback"
}

# Trap to handle script interruption
trap 'error "Deployment interrupted"' INT TERM

# Run main function with all arguments
main "$@"