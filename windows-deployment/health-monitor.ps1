# n8n Health Monitoring Script
# Checks system health and alerts on issues
# Schedule this to run every 5 minutes via Task Scheduler

param(
    [switch]$SendEmail,
    [string]$AlertEmail = "",
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# Configuration
$N8N_URL = "http://localhost:5678"
$DEPLOYMENT_DIR = "C:\n8n-production"
$LOG_FILE = "$DEPLOYMENT_DIR\logs\health-monitor.log"
$ALERT_FILE = "$DEPLOYMENT_DIR\logs\alerts.log"

# Thresholds
$DISK_SPACE_WARNING_GB = 10
$MEMORY_WARNING_PERCENT = 85
$CPU_WARNING_PERCENT = 90

# Initialize
$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$issues = @()
$healthStatus = "HEALTHY"

# Function to log messages
function Write-Log {
    param($Message, $Level = "INFO")
    $logEntry = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LOG_FILE -Value $logEntry
    if ($Verbose -or $Level -eq "ERROR" -or $Level -eq "WARNING") {
        Write-Host $logEntry -ForegroundColor $(if ($Level -eq "ERROR") { "Red" } elseif ($Level -eq "WARNING") { "Yellow" } else { "White" })
    }
}

# Function to send alert
function Send-Alert {
    param($Message)
    Add-Content -Path $ALERT_FILE -Value "[$timestamp] $Message"
    Write-EventLog -LogName Application -Source "n8n-production" -EventId 1001 -EntryType Warning -Message $Message -ErrorAction SilentlyContinue

    if ($SendEmail -and $AlertEmail) {
        # Placeholder for email alerting
        Write-Log "Would send email alert to: $AlertEmail" "INFO"
    }
}

Write-Log "=== Starting Health Check ===" "INFO"

# 1. Check Docker Service
Write-Log "Checking Docker service..." "INFO"
try {
    $dockerService = Get-Service -Name "com.docker.service" -ErrorAction SilentlyContinue
    if (-not $dockerService) {
        $dockerService = Get-Service -Name "docker" -ErrorAction SilentlyContinue
    }

    if ($dockerService.Status -ne "Running") {
        $issues += "Docker service is not running"
        $healthStatus = "CRITICAL"
        Write-Log "Docker service status: $($dockerService.Status)" "ERROR"
    } else {
        Write-Log "Docker service: Running ✓" "INFO"
    }
} catch {
    $issues += "Cannot check Docker service status"
    Write-Log "Error checking Docker: $($_.Exception.Message)" "WARNING"
}

# 2. Check n8n Container
Write-Log "Checking n8n container..." "INFO"
Set-Location $DEPLOYMENT_DIR
try {
    $containers = docker-compose ps -q 2>$null
    if ($LASTEXITCODE -eq 0 -and $containers) {
        $n8nContainer = docker ps --filter "name=n8n" --filter "status=running" -q
        if (-not $n8nContainer) {
            $issues += "n8n container is not running"
            $healthStatus = "CRITICAL"
            Write-Log "n8n container: NOT RUNNING ✗" "ERROR"
        } else {
            Write-Log "n8n container: Running ✓" "INFO"
        }
    } else {
        $issues += "No containers found"
        $healthStatus = "CRITICAL"
        Write-Log "No containers running" "ERROR"
    }
} catch {
    $issues += "Cannot check container status"
    Write-Log "Error checking containers: $($_.Exception.Message)" "WARNING"
}

# 3. Check n8n HTTP Response
Write-Log "Checking n8n HTTP endpoint..." "INFO"
try {
    $response = Invoke-WebRequest -Uri $N8N_URL -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Log "n8n HTTP response: OK (200) ✓" "INFO"
    } else {
        $issues += "n8n HTTP returned status $($response.StatusCode)"
        $healthStatus = "WARNING"
        Write-Log "n8n HTTP status: $($response.StatusCode)" "WARNING"
    }
} catch {
    $issues += "n8n is not responding to HTTP requests"
    $healthStatus = "CRITICAL"
    Write-Log "n8n HTTP check failed: $($_.Exception.Message)" "ERROR"
}

# 4. Check Cloudflare Tunnel
Write-Log "Checking Cloudflare tunnel..." "INFO"
try {
    $cloudflaredContainer = docker ps --filter "name=cloudflared" --filter "status=running" -q
    if ($cloudflaredContainer) {
        Write-Log "Cloudflare tunnel: Running ✓" "INFO"
    } else {
        $issues += "Cloudflare tunnel is not running"
        $healthStatus = if ($healthStatus -eq "CRITICAL") { "CRITICAL" } else { "WARNING" }
        Write-Log "Cloudflare tunnel: NOT RUNNING ✗" "WARNING"
    }
} catch {
    Write-Log "Error checking Cloudflare tunnel: $($_.Exception.Message)" "WARNING"
}

# 5. Check Disk Space
Write-Log "Checking disk space..." "INFO"
try {
    $disk = Get-PSDrive C
    $freeSpaceGB = [math]::Round($disk.Free / 1GB, 2)

    if ($freeSpaceGB -lt $DISK_SPACE_WARNING_GB) {
        $issues += "Low disk space: ${freeSpaceGB}GB remaining"
        $healthStatus = if ($healthStatus -eq "CRITICAL") { "CRITICAL" } else { "WARNING" }
        Write-Log "Disk space: ${freeSpaceGB}GB remaining (LOW) ⚠" "WARNING"
    } else {
        Write-Log "Disk space: ${freeSpaceGB}GB available ✓" "INFO"
    }
} catch {
    Write-Log "Error checking disk space: $($_.Exception.Message)" "WARNING"
}

# 6. Check Memory Usage
Write-Log "Checking memory usage..." "INFO"
try {
    $memory = Get-CimInstance Win32_OperatingSystem
    $usedMemoryPercent = [math]::Round((($memory.TotalVisibleMemorySize - $memory.FreePhysicalMemory) / $memory.TotalVisibleMemorySize) * 100, 2)

    if ($usedMemoryPercent -gt $MEMORY_WARNING_PERCENT) {
        $issues += "High memory usage: ${usedMemoryPercent}%"
        $healthStatus = if ($healthStatus -eq "CRITICAL") { "CRITICAL" } else { "WARNING" }
        Write-Log "Memory usage: ${usedMemoryPercent}% (HIGH) ⚠" "WARNING"
    } else {
        Write-Log "Memory usage: ${usedMemoryPercent}% ✓" "INFO"
    }
} catch {
    Write-Log "Error checking memory: $($_.Exception.Message)" "WARNING"
}

# 7. Check Container Resource Usage
Write-Log "Checking container resources..." "INFO"
try {
    $stats = docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemPerc}}" 2>$null
    if ($stats) {
        Write-Log "Container stats collected ✓" "INFO"
        if ($Verbose) {
            $stats | ForEach-Object { Write-Log $_ "INFO" }
        }
    }
} catch {
    Write-Log "Error getting container stats: $($_.Exception.Message)" "WARNING"
}

# 8. Check for Recent Errors in Docker Logs
Write-Log "Checking recent Docker logs for errors..." "INFO"
try {
    $recentErrors = docker-compose logs --tail=50 2>&1 | Select-String -Pattern "error|fatal|exception" -CaseSensitive:$false
    if ($recentErrors) {
        $errorCount = ($recentErrors | Measure-Object).Count
        $issues += "Found $errorCount error(s) in recent logs"
        $healthStatus = if ($healthStatus -eq "CRITICAL") { "CRITICAL" } else { "WARNING" }
        Write-Log "Recent errors found: $errorCount ⚠" "WARNING"
        if ($Verbose) {
            $recentErrors | Select-Object -First 5 | ForEach-Object { Write-Log $_.Line "WARNING" }
        }
    } else {
        Write-Log "No recent errors in logs ✓" "INFO"
    }
} catch {
    Write-Log "Error checking logs: $($_.Exception.Message)" "WARNING"
}

# Generate Summary Report
Write-Log "=== Health Check Complete ===" "INFO"
Write-Log "Overall Status: $healthStatus" $(if ($healthStatus -eq "HEALTHY") { "INFO" } elseif ($healthStatus -eq "WARNING") { "WARNING" } else { "ERROR" })

if ($issues.Count -gt 0) {
    Write-Log "Issues Found: $($issues.Count)" "WARNING"
    $issueReport = "Issues detected:`n" + ($issues -join "`n")
    Write-Log $issueReport "WARNING"
    Send-Alert $issueReport
} else {
    Write-Log "No issues detected - System is healthy ✓" "INFO"
}

# Return exit code based on health status
if ($healthStatus -eq "CRITICAL") {
    exit 2
} elseif ($healthStatus -eq "WARNING") {
    exit 1
} else {
    exit 0
}
