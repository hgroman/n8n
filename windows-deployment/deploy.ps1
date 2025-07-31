# n8n Windows Server Deployment Script
# This script automates the deployment process on Windows Server

param(
    [switch]$SkipBackup,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Host "=== n8n Windows Server Deployment ===" -ForegroundColor Cyan
Write-Host "Starting deployment process..." -ForegroundColor Green

# Configuration
$DEPLOYMENT_DIR = "C:\n8n-production"
$DOCKER_COMPOSE_FILE = "$DEPLOYMENT_DIR\docker-compose.yml"
$ENV_FILE = "$DEPLOYMENT_DIR\.env"

# Function to check if Docker is running
function Test-DockerRunning {
    try {
        docker version | Out-Null
        return $true
    }
    catch {
        return $false
    }
}

# Function to create directory structure
function New-DeploymentStructure {
    Write-Host "Creating deployment directory structure..." -ForegroundColor Blue
    
    $directories = @(
        $DEPLOYMENT_DIR,
        "$DEPLOYMENT_DIR\cloudflared",
        "$DEPLOYMENT_DIR\n8n-workflows",
        "$DEPLOYMENT_DIR\backups",
        "$DEPLOYMENT_DIR\logs"
    )
    
    foreach ($dir in $directories) {
        if (!(Test-Path -Path $dir)) {
            New-Item -ItemType Directory -Path $dir -Force
            Write-Host "Created: $dir" -ForegroundColor Yellow
        }
    }
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Blue
    
    # Check Docker
    if (!(Test-DockerRunning)) {
        Write-Host "ERROR: Docker is not running or not installed!" -ForegroundColor Red
        Write-Host "Please install Docker Desktop for Windows and ensure it's running." -ForegroundColor Yellow
        exit 1
    }
    Write-Host "✓ Docker is running" -ForegroundColor Green
    
    # Check Docker Compose
    try {
        docker-compose --version | Out-Null
        Write-Host "✓ Docker Compose is available" -ForegroundColor Green
    }
    catch {
        Write-Host "ERROR: Docker Compose is not available!" -ForegroundColor Red
        exit 1
    }
    
    # Check environment file
    if (!(Test-Path -Path $ENV_FILE)) {
        Write-Host "WARNING: .env file not found at $ENV_FILE" -ForegroundColor Yellow
        Write-Host "Please copy .env.example to .env and configure your settings." -ForegroundColor Yellow
        if (!$Force) {
            $continue = Read-Host "Continue without .env file? (y/N)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                exit 1
            }
        }
    }
    else {
        Write-Host "✓ Environment file found" -ForegroundColor Green
    }
}

# Function to backup existing data
function Backup-ExistingData {
    if ($SkipBackup) {
        Write-Host "Skipping backup as requested..." -ForegroundColor Yellow
        return
    }
    
    Write-Host "Creating backup of existing data..." -ForegroundColor Blue
    
    try {
        & "$DEPLOYMENT_DIR\backup.ps1"
        Write-Host "✓ Backup completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Host "WARNING: Backup failed: $($_.Exception.Message)" -ForegroundColor Yellow
        if (!$Force) {
            $continue = Read-Host "Continue without backup? (y/N)"
            if ($continue -ne "y" -and $continue -ne "Y") {
                exit 1
            }
        }
    }
}

# Function to deploy services
function Start-Services {
    Write-Host "Starting n8n services..." -ForegroundColor Blue
    
    Set-Location $DEPLOYMENT_DIR
    
    try {
        # Pull latest images
        docker-compose pull
        
        # Start services
        docker-compose up -d
        
        Write-Host "✓ Services started successfully" -ForegroundColor Green
        
        # Wait for services to be ready
        Write-Host "Waiting for services to be ready..." -ForegroundColor Blue
        Start-Sleep -Seconds 10
        
        # Check service status
        docker-compose ps
        
    }
    catch {
        Write-Host "ERROR: Failed to start services: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

# Function to display post-deployment information
function Show-DeploymentInfo {
    Write-Host ""
    Write-Host "=== Deployment Complete ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "n8n is now running on your Windows Server!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Access URLs:" -ForegroundColor Yellow
    Write-Host "  Local: http://localhost:5678" -ForegroundColor White
    Write-Host "  Public: https://n8n.improvemyrankings.com" -ForegroundColor White
    Write-Host ""
    Write-Host "Important Files:" -ForegroundColor Yellow
    Write-Host "  Configuration: $DOCKER_COMPOSE_FILE" -ForegroundColor White
    Write-Host "  Environment: $ENV_FILE" -ForegroundColor White
    Write-Host "  Backups: $DEPLOYMENT_DIR\backups" -ForegroundColor White
    Write-Host "  Logs: $DEPLOYMENT_DIR\logs" -ForegroundColor White
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Yellow
    Write-Host "  View logs: docker-compose logs -f" -ForegroundColor White
    Write-Host "  Restart: docker-compose restart" -ForegroundColor White
    Write-Host "  Stop: docker-compose down" -ForegroundColor White
    Write-Host "  Backup: .\backup.ps1" -ForegroundColor White
    Write-Host ""
}

# Main execution
try {
    New-DeploymentStructure
    Test-Prerequisites
    Backup-ExistingData
    Start-Services
    Show-DeploymentInfo
}
catch {
    Write-Host "DEPLOYMENT FAILED: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
