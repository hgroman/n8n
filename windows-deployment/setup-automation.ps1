# n8n Automation Setup Script
# Configures Windows Task Scheduler for automated monitoring and backups
# Run as Administrator

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   n8n Automation Setup" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$DEPLOYMENT_DIR = "C:\n8n-production"

# Function to create scheduled task
function New-ScheduledTaskIfNotExists {
    param(
        [string]$TaskName,
        [string]$Description,
        [string]$ScriptPath,
        [string]$Trigger,  # "Daily", "Hourly", "Every5Minutes"
        [string]$Time = "02:00"
    )

    # Check if task already exists
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Write-Host "⚠ Task '$TaskName' already exists" -ForegroundColor Yellow
        $overwrite = Read-Host "Overwrite? (y/N)"
        if ($overwrite -ne "y" -and $overwrite -ne "Y") {
            Write-Host "  └─ Skipped" -ForegroundColor Gray
            return
        }
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Create action
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-ExecutionPolicy Bypass -File `"$ScriptPath`""

    # Create trigger based on type
    switch ($Trigger) {
        "Daily" {
            $triggerObj = New-ScheduledTaskTrigger -Daily -At $Time
        }
        "Hourly" {
            $triggerObj = New-ScheduledTaskTrigger -Once -At $Time -RepetitionInterval (New-TimeSpan -Hours 1) -RepetitionDuration ([TimeSpan]::MaxValue)
        }
        "Every5Minutes" {
            $triggerObj = New-ScheduledTaskTrigger -Once -At $Time -RepetitionInterval (New-TimeSpan -Minutes 5) -RepetitionDuration ([TimeSpan]::MaxValue)
        }
        "Every15Minutes" {
            $triggerObj = New-ScheduledTaskTrigger -Once -At $Time -RepetitionInterval (New-TimeSpan -Minutes 15) -RepetitionDuration ([TimeSpan]::MaxValue)
        }
    }

    # Create settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    # Register task
    Register-ScheduledTask -TaskName $TaskName -Description $Description -Action $action -Trigger $triggerObj -Settings $settings -User "SYSTEM" | Out-Null

    Write-Host "✓ Created task: $TaskName" -ForegroundColor Green
    Write-Host "  └─ Schedule: $Trigger" -ForegroundColor Gray
}

Write-Host "Setting up automated tasks..." -ForegroundColor Blue
Write-Host ""

# Task 1: Daily Backup
Write-Host "[1/3] Daily Backup Task" -ForegroundColor Cyan
New-ScheduledTaskIfNotExists `
    -TaskName "n8n-Daily-Backup" `
    -Description "Automated daily backup of n8n database with verification" `
    -ScriptPath "$DEPLOYMENT_DIR\backup-enhanced.ps1" `
    -Trigger "Daily" `
    -Time "02:00"

# Task 2: Health Monitoring
Write-Host ""
Write-Host "[2/3] Health Monitoring Task" -ForegroundColor Cyan
New-ScheduledTaskIfNotExists `
    -TaskName "n8n-Health-Monitor" `
    -Description "Monitors n8n system health every 15 minutes" `
    -ScriptPath "$DEPLOYMENT_DIR\health-monitor.ps1" `
    -Trigger "Every15Minutes" `
    -Time "00:00"

# Task 3: Weekly Validation
Write-Host ""
Write-Host "[3/3] Weekly Validation Task" -ForegroundColor Cyan
$validationScript = "$DEPLOYMENT_DIR\weekly-validation.ps1"

# Create weekly validation script if it doesn't exist
if (-not (Test-Path $validationScript)) {
    @"
# Weekly n8n validation and maintenance
`$DEPLOYMENT_DIR = "C:\n8n-production"
Set-Location `$DEPLOYMENT_DIR

Write-Host "Starting weekly validation..." -ForegroundColor Cyan

# Run health check
.\health-monitor.ps1 -Verbose

# Run deployment validation
.\validate-deployment.ps1 -PostDeploy

# Test backup restore
.\backup-enhanced.ps1 -TestRestore

# Check for updates
Write-Host "Checking for n8n updates..." -ForegroundColor Blue
docker pull n8nio/n8n:latest

# Log completion
Add-Content -Path "logs\maintenance.log" -Value "`$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - Weekly validation completed"

Write-Host "Weekly validation complete!" -ForegroundColor Green
"@ | Set-Content -Path $validationScript
}

New-ScheduledTaskIfNotExists `
    -TaskName "n8n-Weekly-Validation" `
    -Description "Weekly validation and maintenance checks" `
    -ScriptPath $validationScript `
    -Trigger "Daily" `
    -Time "03:00"

# Configure Event Log Source (for health monitoring alerts)
Write-Host ""
Write-Host "Configuring Windows Event Log..." -ForegroundColor Blue
try {
    if (-not ([System.Diagnostics.EventLog]::SourceExists("n8n-production"))) {
        New-EventLog -LogName Application -Source "n8n-production"
        Write-Host "✓ Event Log source created" -ForegroundColor Green
    } else {
        Write-Host "✓ Event Log source already exists" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠ Could not create Event Log source: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Summary
Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "   AUTOMATION SUMMARY" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

$tasks = Get-ScheduledTask | Where-Object { $_.TaskName -like "n8n-*" }

foreach ($task in $tasks) {
    $status = if ($task.State -eq "Ready") { "✓" } else { "⚠" }
    $color = if ($task.State -eq "Ready") { "Green" } else { "Yellow" }

    Write-Host "$status " -ForegroundColor $color -NoNewline
    Write-Host "$($task.TaskName)" -ForegroundColor White
    Write-Host "  └─ Status: $($task.State)" -ForegroundColor Gray

    # Get next run time
    $taskInfo = Get-ScheduledTaskInfo -TaskName $task.TaskName
    if ($taskInfo.NextRunTime) {
        Write-Host "  └─ Next Run: $($taskInfo.NextRunTime)" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "═══════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

Write-Host "✓ Automation setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "You can manage tasks with:" -ForegroundColor Yellow
Write-Host "  • Task Scheduler: taskschd.msc" -ForegroundColor White
Write-Host "  • PowerShell: Get-ScheduledTask | Where-Object { `$_.TaskName -like 'n8n-*' }" -ForegroundColor White
Write-Host ""
Write-Host "To manually run tasks:" -ForegroundColor Yellow
Write-Host "  Start-ScheduledTask -TaskName 'n8n-Daily-Backup'" -ForegroundColor White
Write-Host "  Start-ScheduledTask -TaskName 'n8n-Health-Monitor'" -ForegroundColor White
Write-Host "  Start-ScheduledTask -TaskName 'n8n-Weekly-Validation'" -ForegroundColor White
Write-Host ""
