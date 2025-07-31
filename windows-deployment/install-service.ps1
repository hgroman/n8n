# Install n8n as a Windows Service
# This script sets up n8n to run automatically on Windows Server startup

#Requires -RunAsAdministrator

param(
    [switch]$Uninstall
)

$SERVICE_NAME = "n8n-production"
$SERVICE_DISPLAY_NAME = "n8n Production Workflow Automation"
$SERVICE_DESCRIPTION = "n8n workflow automation platform running in Docker"
$DEPLOYMENT_DIR = "C:\n8n-production"
$SERVICE_SCRIPT = "$DEPLOYMENT_DIR\service-wrapper.ps1"

function Install-N8nService {
    Write-Host "Installing n8n as Windows Service..." -ForegroundColor Green
    
    # Create service wrapper script
    $wrapperScript = @"
# n8n Service Wrapper Script
Set-Location "$DEPLOYMENT_DIR"
try {
    docker-compose up -d
    Write-EventLog -LogName Application -Source "n8n-production" -EventId 1001 -Message "n8n service started successfully"
}
catch {
    Write-EventLog -LogName Application -Source "n8n-production" -EventId 1002 -EntryType Error -Message "Failed to start n8n service: `$(`$_.Exception.Message)"
    exit 1
}
"@
    
    $wrapperScript | Out-File -FilePath $SERVICE_SCRIPT -Encoding UTF8
    
    # Create the service
    $servicePath = "powershell.exe -ExecutionPolicy Bypass -File `"$SERVICE_SCRIPT`""
    
    try {
        New-Service -Name $SERVICE_NAME -BinaryPathName $servicePath -DisplayName $SERVICE_DISPLAY_NAME -Description $SERVICE_DESCRIPTION -StartupType Automatic
        Write-Host "✓ Service '$SERVICE_NAME' created successfully" -ForegroundColor Green
        
        # Create event log source
        New-EventLog -LogName Application -Source "n8n-production" -ErrorAction SilentlyContinue
        
        # Set service to restart on failure
        sc.exe failure $SERVICE_NAME reset= 86400 actions= restart/5000/restart/5000/restart/5000
        
        Write-Host "✓ Service configured to restart on failure" -ForegroundColor Green
        
    }
    catch {
        Write-Host "ERROR: Failed to create service: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

function Uninstall-N8nService {
    Write-Host "Uninstalling n8n Windows Service..." -ForegroundColor Yellow
    
    try {
        # Stop the service if running
        $service = Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue
        if ($service -and $service.Status -eq "Running") {
            Stop-Service -Name $SERVICE_NAME -Force
            Write-Host "✓ Service stopped" -ForegroundColor Green
        }
        
        # Remove the service
        Remove-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue
        Write-Host "✓ Service removed" -ForegroundColor Green
        
        # Clean up wrapper script
        if (Test-Path $SERVICE_SCRIPT) {
            Remove-Item $SERVICE_SCRIPT -Force
            Write-Host "✓ Service wrapper script removed" -ForegroundColor Green
        }
        
    }
    catch {
        Write-Host "ERROR: Failed to uninstall service: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }
}

function Show-ServiceInfo {
    Write-Host ""
    Write-Host "=== n8n Windows Service Information ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Service Name: $SERVICE_NAME" -ForegroundColor White
    Write-Host "Display Name: $SERVICE_DISPLAY_NAME" -ForegroundColor White
    Write-Host "Description: $SERVICE_DESCRIPTION" -ForegroundColor White
    Write-Host ""
    Write-Host "Management Commands:" -ForegroundColor Yellow
    Write-Host "  Start Service: Start-Service -Name '$SERVICE_NAME'" -ForegroundColor White
    Write-Host "  Stop Service: Stop-Service -Name '$SERVICE_NAME'" -ForegroundColor White
    Write-Host "  Restart Service: Restart-Service -Name '$SERVICE_NAME'" -ForegroundColor White
    Write-Host "  Service Status: Get-Service -Name '$SERVICE_NAME'" -ForegroundColor White
    Write-Host ""
    Write-Host "Event Log: Check Application Event Log for 'n8n-production' events" -ForegroundColor White
    Write-Host ""
}

# Main execution
if ($Uninstall) {
    Uninstall-N8nService
}
else {
    # Check if running as administrator
    if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
        Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
        Write-Host "Please right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
        exit 1
    }
    
    # Check if service already exists
    $existingService = Get-Service -Name $SERVICE_NAME -ErrorAction SilentlyContinue
    if ($existingService) {
        Write-Host "Service '$SERVICE_NAME' already exists!" -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to reinstall it? (y/N)"
        if ($overwrite -eq "y" -or $overwrite -eq "Y") {
            Uninstall-N8nService
            Install-N8nService
        }
        else {
            Write-Host "Installation cancelled." -ForegroundColor Yellow
            exit 0
        }
    }
    else {
        Install-N8nService
    }
    
    Show-ServiceInfo
}
