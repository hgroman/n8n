# n8n Automated Database Backup Script for Windows Server
# PowerShell version of the original bash script

# --- Configuration ---
# The name of the n8n data volume as defined in your docker-compose.yml
$VOLUME_NAME = "windows-deployment_n8n_data"

# The absolute path on Windows where backups will be stored
$BACKUP_DIR = "C:\n8n-production\backups"

# How many days of backups to keep
$RETENTION_DAYS = 7

# --- Script ---

Write-Host "Starting n8n backup..." -ForegroundColor Green

# Create the backup directory if it doesn't exist
if (!(Test-Path -Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR -Force
    Write-Host "Created backup directory: $BACKUP_DIR" -ForegroundColor Yellow
}

# Create a timestamped backup filename
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BACKUP_FILE = "database_backup_$TIMESTAMP.sqlite"

# Use a temporary container to copy the database file from the volume to the host
Write-Host "Copying database from volume..." -ForegroundColor Blue

try {
    docker run --rm `
        -v "${VOLUME_NAME}:/volume:ro" `
        -v "${BACKUP_DIR}:/backup" `
        alpine cp /volume/database.sqlite /backup/$BACKUP_FILE

    Write-Host "Backup successful: $BACKUP_DIR\$BACKUP_FILE" -ForegroundColor Green
}
catch {
    Write-Host "Backup failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Clean up old backups
Write-Host "Cleaning up old backups..." -ForegroundColor Blue

try {
    $cutoffDate = (Get-Date).AddDays(-$RETENTION_DAYS)
    Get-ChildItem -Path $BACKUP_DIR -Filter "database_backup_*.sqlite" | 
        Where-Object { $_.LastWriteTime -lt $cutoffDate } | 
        Remove-Item -Force

    Write-Host "Old backups removed. Backup process complete." -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not clean up old backups: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Display backup summary
$backupCount = (Get-ChildItem -Path $BACKUP_DIR -Filter "database_backup_*.sqlite").Count
Write-Host "Total backups retained: $backupCount" -ForegroundColor Cyan
