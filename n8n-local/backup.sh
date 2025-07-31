#!/bin/bash
#
# n8n Automated Database Backup Script (Corrected for macOS)
#

# --- Configuration ---
# The name of the n8n data volume as defined in your docker-compose.yml
VOLUME_NAME="n8n-local_n8n_data"

# The absolute path on your Mac where backups will be stored
BACKUP_DIR="/Users/henrygroman/n8n_backups"

# How many days of backups to keep
RETENTION_DAYS=7

# --- Script --- 

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting n8n backup..."

# Create the backup directory on the host if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create a timestamped backup filename
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="database_backup_$TIMESTAMP.sqlite"

# Use a temporary container to copy the database file from the volume to the host
echo "Copying database from volume..."
docker run --rm \
    -v "$VOLUME_NAME:/volume:ro" \
    -v "$BACKUP_DIR:/backup" \
    alpine cp /volume/database.sqlite /backup/"$BACKUP_FILE"

echo "Backup successful: $BACKUP_DIR/$BACKUP_FILE"

# Clean up old backups
echo "Cleaning up old backups..."
find "$BACKUP_DIR" -name "database_backup_*.sqlite" -mtime +$RETENTION_DAYS -exec rm {} \;

echo "Old backups removed. Backup process complete."
