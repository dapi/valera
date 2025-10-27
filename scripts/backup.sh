#!/bin/bash

# Database Backup Script for Valera Production
# This script creates automated database backups with S3 sync

set -euo pipefail

# Configuration
POSTGRES_DB="${POSTGRES_DB:-valera_production}"
POSTGRES_USER="${POSTGRES_USER:-postgres}"
BACKUP_DIR="/backups"
S3_BUCKET="${S3_BUCKET:-valera-backups}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${POSTGRES_DB}_${TIMESTAMP}.sql"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1" >&2
}

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Database backup
log "Creating database backup: $BACKUP_FILE"

if ! pg_dump -h postgres -U "$POSTGRES_USER" -d "$POSTGRES_DB" > "$BACKUP_DIR/$BACKUP_FILE"; then
    error "Database backup failed"
fi

# Compress backup
log "Compressing backup..."
gzip "$BACKUP_DIR/$BACKUP_FILE"
BACKUP_FILE="${BACKUP_FILE}.gz"

# Verify backup integrity
log "Verifying backup integrity..."
if ! gzip -t "$BACKUP_DIR/$BACKUP_FILE"; then
    error "Backup integrity check failed"
fi

# Upload to S3 if configured
if [[ -n "${AWS_ACCESS_KEY_ID:-}" && -n "${AWS_SECRET_ACCESS_KEY:-}" ]]; then
    log "Uploading backup to S3..."

    if command -v aws &> /dev/null; then
        aws s3 cp "$BACKUP_DIR/$BACKUP_FILE" "s3://$S3_BUCKET/database/" || warning "S3 upload failed"
    else
        warning "AWS CLI not found, skipping S3 upload"
    fi
else
    warning "AWS credentials not configured, skipping S3 upload"
fi

# Clean up old backups
log "Cleaning up old backups (keeping last $RETENTION_DAYS days)..."
find "$BACKUP_DIR" -name "${POSTGRES_DB}_*.sql.gz" -mtime +$RETENTION_DAYS -delete

# Clean up old S3 backups if AWS CLI is available
if command -v aws &> /dev/null && [[ -n "${AWS_ACCESS_KEY_ID:-}" ]]; then
    log "Cleaning up old S3 backups..."
    aws s3 ls "s3://$S3_BUCKET/database/" | \
        awk '$1 < "'"$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)"'" {print $4}' | \
        xargs -I {} aws s3 rm "s3://$S3_BUCKET/database/{}" || true
fi

log "Backup completed successfully: $BACKUP_FILE"

# Display backup info
BACKUP_SIZE=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
log "Backup size: $BACKUP_SIZE"
log "Backup location: $BACKUP_DIR/$BACKUP_FILE"

# Keep local backup count limited
LOCAL_BACKUPS_TO_KEEP=5
log "Keeping last $LOCAL_BACKUPS_TO_KEEP local backups..."
ls -t "$BACKUP_DIR"/${POSTGRES_DB}_*.sql.gz | tail -n +$((LOCAL_BACKUPS_TO_KEEP + 1)) | xargs rm -f