# n8n Deployment Validation Script
# Comprehensive pre-deployment and post-deployment checks
# Run this before deploying to catch configuration issues

param(
    [switch]$PreDeploy,
    [switch]$PostDeploy,
    [switch]$Detailed
)

$ErrorActionPreference = "Continue"

# Configuration
$DEPLOYMENT_DIR = "C:\n8n-production"
$REQUIRED_PORTS = @(5678)
$REQUIRED_FILES = @(
    "docker-compose.yml",
    ".env",
    "cloudflared\config.yml"
)

# Colors for output
$script:PassCount = 0
$script:FailCount = 0
$script:WarnCount = 0

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Message = "",
        [string]$Severity = "ERROR"
    )

    if ($Passed) {
        Write-Host "✓ " -ForegroundColor Green -NoNewline
        Write-Host "$TestName" -ForegroundColor White
        if ($Message -and $Detailed) {
            Write-Host "  └─ $Message" -ForegroundColor Gray
        }
        $script:PassCount++
    } else {
        if ($Severity -eq "WARNING") {
            Write-Host "⚠ " -ForegroundColor Yellow -NoNewline
            Write-Host "$TestName" -ForegroundColor Yellow
            if ($Message) {
                Write-Host "  └─ $Message" -ForegroundColor Yellow
            }
            $script:WarnCount++
        } else {
            Write-Host "✗ " -ForegroundColor Red -NoNewline
            Write-Host "$TestName" -ForegroundColor Red
            if ($Message) {
                Write-Host "  └─ $Message" -ForegroundColor Red
            }
            $script:FailCount++
        }
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   n8n Deployment Validation" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# PRE-DEPLOYMENT CHECKS
if ($PreDeploy -or (-not $PostDeploy)) {
    Write-Host "🔍 PRE-DEPLOYMENT CHECKS" -ForegroundColor Cyan
    Write-Host ""

    # Check 1: Docker Desktop Running
    Write-Host "[1/15] Docker Service..." -ForegroundColor Blue
    try {
        docker version | Out-Null
        Write-TestResult "Docker is installed and running" $true
    } catch {
        Write-TestResult "Docker is installed and running" $false "Docker is not running or not installed"
    }

    # Check 2: Docker Compose Available
    Write-Host "[2/15] Docker Compose..." -ForegroundColor Blue
    try {
        docker-compose --version | Out-Null
        Write-TestResult "Docker Compose is available" $true
    } catch {
        Write-TestResult "Docker Compose is available" $false "Docker Compose not found"
    }

    # Check 3: Deployment Directory
    Write-Host "[3/15] Deployment Directory..." -ForegroundColor Blue
    if (Test-Path $DEPLOYMENT_DIR) {
        Write-TestResult "Deployment directory exists" $true "$DEPLOYMENT_DIR"
        Set-Location $DEPLOYMENT_DIR
    } else {
        Write-TestResult "Deployment directory exists" $false "$DEPLOYMENT_DIR not found"
    }

    # Check 4: Required Files
    Write-Host "[4/15] Required Files..." -ForegroundColor Blue
    foreach ($file in $REQUIRED_FILES) {
        $filePath = Join-Path $DEPLOYMENT_DIR $file
        if (Test-Path $filePath) {
            Write-TestResult "Found $file" $true
        } else {
            Write-TestResult "Found $file" $false "Missing required file"
        }
    }

    # Check 5: Environment File Configuration
    Write-Host "[5/15] Environment Configuration..." -ForegroundColor Blue
    $envFile = Join-Path $DEPLOYMENT_DIR ".env"
    if (Test-Path $envFile) {
        $envContent = Get-Content $envFile -Raw

        # Check for default password
        if ($envContent -match "N8N_BASIC_AUTH_PASSWORD=changeme") {
            Write-TestResult "Production password configured" $false "Still using default password 'changeme'" "WARNING"
        } elseif ($envContent -match "N8N_BASIC_AUTH_PASSWORD=.+") {
            Write-TestResult "Production password configured" $true
        } else {
            Write-TestResult "Production password configured" $false "Password not set" "WARNING"
        }

        # Check for encryption key
        if ($envContent -match "N8N_ENCRYPTION_KEY=.{32,}") {
            Write-TestResult "Encryption key configured" $true
        } else {
            Write-TestResult "Encryption key configured" $false "Missing or too short (need 32+ chars)" "WARNING"
        }
    }

    # Check 6: Port Availability
    Write-Host "[6/15] Port Availability..." -ForegroundColor Blue
    foreach ($port in $REQUIRED_PORTS) {
        $portInUse = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
        if ($portInUse) {
            Write-TestResult "Port $port available" $false "Port already in use" "WARNING"
        } else {
            Write-TestResult "Port $port available" $true
        }
    }

    # Check 7: Disk Space
    Write-Host "[7/15] Disk Space..." -ForegroundColor Blue
    $disk = Get-PSDrive C
    $freeSpaceGB = [math]::Round($disk.Free / 1GB, 2)
    if ($freeSpaceGB -gt 20) {
        Write-TestResult "Sufficient disk space" $true "${freeSpaceGB}GB available"
    } elseif ($freeSpaceGB -gt 10) {
        Write-TestResult "Sufficient disk space" $true "${freeSpaceGB}GB available (consider cleanup soon)" "WARNING"
    } else {
        Write-TestResult "Sufficient disk space" $false "Only ${freeSpaceGB}GB available"
    }

    # Check 8: Available Memory
    Write-Host "[8/15] System Memory..." -ForegroundColor Blue
    $memory = Get-CimInstance Win32_OperatingSystem
    $totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize / 1MB, 2)
    $freeMemoryGB = [math]::Round($memory.FreePhysicalMemory / 1MB, 2)

    if ($totalMemoryGB -ge 4) {
        Write-TestResult "Sufficient memory (4GB+ recommended)" $true "${totalMemoryGB}GB total, ${freeMemoryGB}GB free"
    } else {
        Write-TestResult "Sufficient memory (4GB+ recommended)" $false "Only ${totalMemoryGB}GB total" "WARNING"
    }

    # Check 9: Cloudflare Configuration
    Write-Host "[9/15] Cloudflare Tunnel Config..." -ForegroundColor Blue
    $cloudflareConfig = Join-Path $DEPLOYMENT_DIR "cloudflared\config.yml"
    if (Test-Path $cloudflareConfig) {
        $configContent = Get-Content $cloudflareConfig -Raw

        if ($configContent -match "your-tunnel-id-here") {
            Write-TestResult "Cloudflare tunnel ID configured" $false "Placeholder tunnel ID detected"
        } else {
            Write-TestResult "Cloudflare tunnel ID configured" $true
        }

        # Check for certificate
        $certPath = Join-Path $DEPLOYMENT_DIR "cloudflared\cert.pem"
        if (Test-Path $certPath) {
            Write-TestResult "Cloudflare certificate present" $true
        } else {
            Write-TestResult "Cloudflare certificate present" $false "cert.pem not found" "WARNING"
        }
    } else {
        Write-TestResult "Cloudflare configuration found" $false
    }

    # Check 10: Workflow Directory
    Write-Host "[10/15] Workflow Directory..." -ForegroundColor Blue
    $workflowDir = Join-Path $DEPLOYMENT_DIR "n8n-workflows"
    if (Test-Path $workflowDir) {
        $workflowCount = (Get-ChildItem $workflowDir -Filter "*.json" -ErrorAction SilentlyContinue | Measure-Object).Count
        Write-TestResult "Workflow directory exists" $true "$workflowCount workflow(s) ready to import"
    } else {
        Write-TestResult "Workflow directory exists" $false "Create directory or workflows won't be available" "WARNING"
    }

    # Check 11: Backup Directory
    Write-Host "[11/15] Backup Directory..." -ForegroundColor Blue
    $backupDir = Join-Path $DEPLOYMENT_DIR "backups"
    if (Test-Path $backupDir) {
        Write-TestResult "Backup directory exists" $true
    } else {
        New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
        Write-TestResult "Backup directory created" $true "Created automatically"
    }

    # Check 12: Logs Directory
    Write-Host "[12/15] Logs Directory..." -ForegroundColor Blue
    $logsDir = Join-Path $DEPLOYMENT_DIR "logs"
    if (Test-Path $logsDir) {
        Write-TestResult "Logs directory exists" $true
    } else {
        New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
        Write-TestResult "Logs directory created" $true "Created automatically"
    }

    # Check 13: Backup Script
    Write-Host "[13/15] Backup Script..." -ForegroundColor Blue
    $backupScript = Join-Path $DEPLOYMENT_DIR "backup.ps1"
    if (Test-Path $backupScript) {
        Write-TestResult "Backup script present" $true
    } else {
        Write-TestResult "Backup script present" $false "backup.ps1 not found" "WARNING"
    }

    # Check 14: Windows Firewall
    Write-Host "[14/15] Windows Firewall..." -ForegroundColor Blue
    try {
        $firewallRule = Get-NetFirewallRule -DisplayName "n8n-local" -ErrorAction SilentlyContinue
        if ($firewallRule) {
            Write-TestResult "Firewall rule configured" $true
        } else {
            Write-TestResult "Firewall rule configured" $false "No firewall rule found (may be needed for local access)" "WARNING"
        }
    } catch {
        Write-TestResult "Firewall check" $false "Unable to check firewall rules" "WARNING"
    }

    # Check 15: WSL2 (for Docker Desktop)
    Write-Host "[15/15] WSL2 Backend..." -ForegroundColor Blue
    try {
        $wsl = wsl --list 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "WSL2 available" $true "Required for Docker Desktop"
        } else {
            Write-TestResult "WSL2 available" $false "WSL2 may not be installed" "WARNING"
        }
    } catch {
        Write-TestResult "WSL2 check" $false "Unable to verify WSL2" "WARNING"
    }
}

# POST-DEPLOYMENT CHECKS
if ($PostDeploy) {
    Write-Host ""
    Write-Host "🔍 POST-DEPLOYMENT CHECKS" -ForegroundColor Cyan
    Write-Host ""

    Set-Location $DEPLOYMENT_DIR

    # Check 1: Containers Running
    Write-Host "[1/8] Container Status..." -ForegroundColor Blue
    try {
        $runningContainers = docker-compose ps -q
        if ($runningContainers) {
            $containerCount = ($runningContainers | Measure-Object).Count
            Write-TestResult "Docker containers running" $true "$containerCount container(s)"
        } else {
            Write-TestResult "Docker containers running" $false "No containers found"
        }
    } catch {
        Write-TestResult "Docker containers running" $false $_.Exception.Message
    }

    # Check 2: n8n Container Health
    Write-Host "[2/8] n8n Container..." -ForegroundColor Blue
    $n8nContainer = docker ps --filter "name=n8n" --filter "status=running" -q
    if ($n8nContainer) {
        Write-TestResult "n8n container healthy" $true
    } else {
        Write-TestResult "n8n container healthy" $false "Container not running"
    }

    # Check 3: Cloudflared Container
    Write-Host "[3/8] Cloudflare Tunnel..." -ForegroundColor Blue
    $cloudflaredContainer = docker ps --filter "name=cloudflared" --filter "status=running" -q
    if ($cloudflaredContainer) {
        Write-TestResult "Cloudflare tunnel healthy" $true
    } else {
        Write-TestResult "Cloudflare tunnel healthy" $false "Tunnel not running" "WARNING"
    }

    # Check 4: n8n HTTP Response
    Write-Host "[4/8] n8n HTTP Endpoint..." -ForegroundColor Blue
    try {
        Start-Sleep -Seconds 2  # Give it a moment
        $response = Invoke-WebRequest -Uri "http://localhost:5678" -TimeoutSec 10 -UseBasicParsing -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-TestResult "n8n responding to HTTP" $true "Status 200 OK"
        } else {
            Write-TestResult "n8n responding to HTTP" $false "Status: $($response.StatusCode)"
        }
    } catch {
        Write-TestResult "n8n responding to HTTP" $false $_.Exception.Message
    }

    # Check 5: Volume Mounts
    Write-Host "[5/8] Docker Volumes..." -ForegroundColor Blue
    try {
        $volumes = docker volume ls -q | Select-String "n8n"
        if ($volumes) {
            Write-TestResult "Docker volumes created" $true
        } else {
            Write-TestResult "Docker volumes created" $false "No n8n volumes found" "WARNING"
        }
    } catch {
        Write-TestResult "Docker volumes" $false $_.Exception.Message "WARNING"
    }

    # Check 6: Container Logs (errors)
    Write-Host "[6/8] Recent Container Logs..." -ForegroundColor Blue
    try {
        $errors = docker-compose logs --tail=20 2>&1 | Select-String -Pattern "error|fatal" -CaseSensitive:$false
        if ($errors) {
            $errorCount = ($errors | Measure-Object).Count
            Write-TestResult "No errors in logs" $false "Found $errorCount error(s) in recent logs" "WARNING"
        } else {
            Write-TestResult "No errors in logs" $true
        }
    } catch {
        Write-TestResult "Log check" $false $_.Exception.Message "WARNING"
    }

    # Check 7: Database File
    Write-Host "[7/8] Database Initialization..." -ForegroundColor Blue
    try {
        $dbCheck = docker exec -i $(docker-compose ps -q n8n) test -f /home/node/.n8n/database.sqlite
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Database file created" $true
        } else {
            Write-TestResult "Database file created" $false "database.sqlite not found" "WARNING"
        }
    } catch {
        Write-TestResult "Database check" $false $_.Exception.Message "WARNING"
    }

    # Check 8: Public URL (if configured)
    Write-Host "[8/8] Public URL Access..." -ForegroundColor Blue
    try {
        $publicUrl = "https://n8n.improvemyrankings.com"
        $publicResponse = Invoke-WebRequest -Uri $publicUrl -TimeoutSec 15 -UseBasicParsing -ErrorAction Stop
        if ($publicResponse.StatusCode -eq 200) {
            Write-TestResult "Public URL accessible" $true "$publicUrl"
        } else {
            Write-TestResult "Public URL accessible" $false "Status: $($publicResponse.StatusCode)" "WARNING"
        }
    } catch {
        Write-TestResult "Public URL accessible" $false "Unable to reach public URL (Cloudflare tunnel may need time)" "WARNING"
    }
}

# Summary Report
Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   VALIDATION SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""
Write-Host "  ✓ Passed:   $script:PassCount" -ForegroundColor Green
Write-Host "  ⚠ Warnings: $script:WarnCount" -ForegroundColor Yellow
Write-Host "  ✗ Failed:   $script:FailCount" -ForegroundColor Red
Write-Host ""

if ($script:FailCount -eq 0 -and $script:WarnCount -eq 0) {
    Write-Host "🎉 All checks passed! Ready to deploy." -ForegroundColor Green
    exit 0
} elseif ($script:FailCount -eq 0) {
    Write-Host "⚠ Passed with warnings. Review warnings above." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "❌ Validation failed. Fix errors before deploying." -ForegroundColor Red
    exit 2
}
