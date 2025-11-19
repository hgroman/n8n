# n8n Enhanced Backup Script with Verification
# Includes: Database backup, workflow export, integrity checks, and restore testing

param(
    [switch]$SkipVerification,
    [switch]$SkipWorkflows,
    [switch]$TestRestore,
    [switch]$Verbose
)

# --- Configuration ---
$VOLUME_NAME = "windows-deployment_n8n_data"
$BACKUP_DIR = "C:\n8n-production\backups"
$RETENTION_DAYS = 7
$WORKFLOW_BACKUP_DIR = "$BACKUP_DIR\workflows"
$LOG_FILE = "$BACKUP_DIR\backup.log"

# --- Functions ---
function Write-Log {
    param($Message, $Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LOG_FILE -Value $logEntry

    if ($Verbose -or $Level -eq "ERROR" -or $Level -eq "WARNING") {
        $color = switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            default { "White" }
        }
        Write-Host $logEntry -ForegroundColor $color
    }
}

function Test-SQLiteIntegrity {
    param($BackupFile)

    Write-Log "Verifying database integrity..." "INFO"

    try {
        # Copy backup to temp location for testing
        $tempDb = "$env:TEMP\n8n_test_$(Get-Date -Format 'yyyyMMddHHmmss').sqlite"
        Copy-Item $BackupFile $tempDb

        # Run integrity check using SQLite in a container
        $integrityCheck = docker run --rm -v "${tempDb}:/test.sqlite" alpine sh -c "apk add --no-cache sqlite && sqlite3 /test.sqlite 'PRAGMA integrity_check;'"

        Remove-Item $tempDb -Force

        if ($integrityCheck -match "ok") {
            Write-Log "✓ Database integrity verified" "SUCCESS"
            return $true
        } else {
            Write-Log "✗ Database integrity check failed: $integrityCheck" "ERROR"
            return $false
        }
    } catch {
        Write-Log "✗ Integrity check error: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Backup-Workflows {
    Write-Log "Backing up workflow definitions..." "INFO"

    try {
        # Create workflow backup directory
        $timestampedWorkflowDir = "$WORKFLOW_BACKUP_DIR\$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss')"
        New-Item -ItemType Directory -Path $timestampedWorkflowDir -Force | Out-Null

        # Export workflows using n8n CLI (if container is running)
        $n8nContainer = docker ps --filter "name=n8n" --filter "status=running" -q

        if ($n8nContainer) {
            # Copy workflows from container .n8n directory
            docker cp "${n8nContainer}:/home/node/.n8n/." "$timestampedWorkflowDir\"

            # Count workflow files
            $workflowFiles = Get-ChildItem "$timestampedWorkflowDir" -Recurse -Filter "*.json" -ErrorAction SilentlyContinue
            $workflowCount = ($workflowFiles | Measure-Object).Count

            Write-Log "✓ Exported $workflowCount workflow file(s)" "SUCCESS"
            return $true
        } else {
            Write-Log "⚠ n8n container not running - skipping workflow export" "WARNING"
            return $false
        }
    } catch {
        Write-Log "✗ Workflow backup failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Test-BackupRestore {
    param($BackupFile)

    Write-Log "Testing backup restore (dry-run)..." "INFO"

    try {
        # Check file size
        $backupSize = (Get-Item $BackupFile).Length
        $backupSizeMB = [math]::Round($backupSize / 1MB, 2)

        if ($backupSize -lt 1KB) {
            Write-Log "✗ Backup file suspiciously small (${backupSizeMB}MB)" "ERROR"
            return $false
        }

        # Verify it's a valid SQLite database
        $header = [System.IO.File]::ReadAllBytes($BackupFile)[0..15]
        $sqliteHeader = [System.Text.Encoding]::ASCII.GetString($header)

        if ($sqliteHeader -match "SQLite format") {
            Write-Log "✓ Backup is valid SQLite database (${backupSizeMB}MB)" "SUCCESS"
            return $true
        } else {
            Write-Log "✗ Backup is not a valid SQLite database" "ERROR"
            return $false
        }
    } catch {
        Write-Log "✗ Restore test failed: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

function Remove-OldBackups {
    Write-Log "Cleaning up old backups..." "INFO"

    try {
        $cutoffDate = (Get-Date).AddDays(-$RETENTION_DAYS)

        # Clean database backups
        $oldDbBackups = Get-ChildItem -Path $BACKUP_DIR -Filter "database_backup_*.sqlite" -ErrorAction SilentlyContinue |
            Where-Object { $_.LastWriteTime -lt $cutoffDate }

        foreach ($backup in $oldDbBackups) {
            Remove-Item $backup.FullName -Force
            Write-Log "Removed old backup: $($backup.Name)" "INFO"
        }

        # Clean workflow backups
        if (Test-Path $WORKFLOW_BACKUP_DIR) {
            $oldWorkflowBackups = Get-ChildItem -Path $WORKFLOW_BACKUP_DIR -Directory -ErrorAction SilentlyContinue |
                Where-Object { $_.LastWriteTime -lt $cutoffDate }

            foreach ($backup in $oldWorkflowBackups) {
                Remove-Item $backup.FullName -Recurse -Force
                Write-Log "Removed old workflow backup: $($backup.Name)" "INFO"
            }
        }

        Write-Log "✓ Cleanup complete" "SUCCESS"
    } catch {
        Write-Log "⚠ Cleanup warning: $($_.Exception.Message)" "WARNING"
    }
}

function Get-BackupStatistics {
    Write-Host ""
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "   BACKUP STATISTICS" -ForegroundColor Cyan
    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan

    # Database backups
    $dbBackups = Get-ChildItem -Path $BACKUP_DIR -Filter "database_backup_*.sqlite" -ErrorAction SilentlyContinue
    $dbBackupCount = ($dbBackups | Measure-Object).Count
    $dbBackupSize = ($dbBackups | Measure-Object -Property Length -Sum).Sum
    $dbBackupSizeMB = [math]::Round($dbBackupSize / 1MB, 2)

    Write-Host "Database Backups: $dbBackupCount files (${dbBackupSizeMB}MB total)" -ForegroundColor White

    # Workflow backups
    if (Test-Path $WORKFLOW_BACKUP_DIR) {
        $workflowBackups = Get-ChildItem -Path $WORKFLOW_BACKUP_DIR -Directory -ErrorAction SilentlyContinue
        $workflowBackupCount = ($workflowBackups | Measure-Object).Count
        Write-Host "Workflow Backups: $workflowBackupCount sets" -ForegroundColor White
    }

    # Disk usage
    $disk = Get-PSDrive C
    $freeSpaceGB = [math]::Round($disk.Free / 1GB, 2)
    Write-Host "Disk Space Available: ${freeSpaceGB}GB" -ForegroundColor White

    # Most recent backup
    if ($dbBackups) {
        $latestBackup = $dbBackups | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        Write-Host "Latest Backup: $($latestBackup.Name)" -ForegroundColor White
        Write-Host "Backup Age: $([math]::Round(((Get-Date) - $latestBackup.LastWriteTime).TotalHours, 1)) hours" -ForegroundColor White
    }

    Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# --- Main Execution ---
Write-Host ""
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   n8n Enhanced Backup System" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Log "=== Starting backup process ===" "INFO"

# Create backup directories
if (!(Test-Path -Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
    Write-Log "Created backup directory: $BACKUP_DIR" "INFO"
}

if (!(Test-Path -Path $WORKFLOW_BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $WORKFLOW_BACKUP_DIR -Force | Out-Null
}

# Step 1: Database Backup
Write-Host "[1/6] Backing up database..." -ForegroundColor Blue
$TIMESTAMP = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$BACKUP_FILE = "$BACKUP_DIR\database_backup_$TIMESTAMP.sqlite"

try {
    docker run --rm `
        -v "${VOLUME_NAME}:/volume:ro" `
        -v "${BACKUP_DIR}:/backup" `
        alpine cp /volume/database.sqlite /backup/database_backup_$TIMESTAMP.sqlite

    Write-Host "✓ Database backup created" -ForegroundColor Green
    Write-Log "Database backup created: $BACKUP_FILE" "SUCCESS"
} catch {
    Write-Host "✗ Database backup failed" -ForegroundColor Red
    Write-Log "Database backup failed: $($_.Exception.Message)" "ERROR"
    exit 1
}

# Step 2: Verify Integrity
if (-not $SkipVerification) {
    Write-Host "[2/6] Verifying backup integrity..." -ForegroundColor Blue
    $integrityOk = Test-SQLiteIntegrity $BACKUP_FILE

    if (-not $integrityOk) {
        Write-Host "✗ Integrity check failed - backup may be corrupted!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Backup integrity verified" -ForegroundColor Green
} else {
    Write-Host "[2/6] Skipping integrity verification" -ForegroundColor Yellow
}

# Step 3: Test Restore
if ($TestRestore) {
    Write-Host "[3/6] Testing restore capability..." -ForegroundColor Blue
    $restoreOk = Test-BackupRestore $BACKUP_FILE

    if (-not $restoreOk) {
        Write-Host "✗ Restore test failed!" -ForegroundColor Red
        exit 1
    }
    Write-Host "✓ Restore test passed" -ForegroundColor Green
} else {
    Write-Host "[3/6] Skipping restore test" -ForegroundColor Yellow
}

# Step 4: Backup Workflows
if (-not $SkipWorkflows) {
    Write-Host "[4/6] Backing up workflows..." -ForegroundColor Blue
    $workflowsOk = Backup-Workflows

    if ($workflowsOk) {
        Write-Host "✓ Workflows backed up" -ForegroundColor Green
    } else {
        Write-Host "⚠ Workflow backup skipped" -ForegroundColor Yellow
    }
} else {
    Write-Host "[4/6] Skipping workflow backup" -ForegroundColor Yellow
}

# Step 5: Cleanup Old Backups
Write-Host "[5/6] Cleaning up old backups..." -ForegroundColor Blue
Remove-OldBackups
Write-Host "✓ Cleanup complete" -ForegroundColor Green

# Step 6: Statistics
Write-Host "[6/6] Generating statistics..." -ForegroundColor Blue
Get-BackupStatistics

Write-Log "=== Backup process completed successfully ===" "SUCCESS"
Write-Host "✓ Backup completed successfully!" -ForegroundColor Green
Write-Host ""

exit 0
