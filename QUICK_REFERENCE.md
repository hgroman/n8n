# n8n Quick Reference Guide
**The 80/20 Guide: Essential Commands & Troubleshooting**

> This guide contains the 20% of commands and procedures you'll use 80% of the time.

---

## 🚀 Quick Start Commands

### Deploy n8n (Windows)
```powershell
cd C:\n8n-production

# Validate configuration before deploying
.\validate-deployment.ps1 -PreDeploy

# Deploy
.\deploy.ps1

# Validate after deployment
.\validate-deployment.ps1 -PostDeploy
```

### Deploy n8n (macOS)
```bash
cd ~/n8n/n8n-local
docker-compose up -d
```

### Access n8n
- **Local**: http://localhost:5678
- **Public**: https://n8n.improvemyrankings.com
- **Default Credentials**: admin / [see .env file]

---

## 📊 Daily Operations

### Check System Health
```powershell
# Quick health check (Windows)
.\health-monitor.ps1

# Detailed health check
.\health-monitor.ps1 -Verbose

# View logs in real-time
docker-compose logs -f

# View only n8n logs
docker-compose logs -f n8n

# View last 100 lines
docker-compose logs --tail=100
```

### Container Management
```powershell
# View running containers
docker-compose ps

# Restart all services
docker-compose restart

# Restart only n8n
docker-compose restart n8n

# Stop all services
docker-compose down

# Stop and remove volumes (DESTRUCTIVE!)
docker-compose down -v

# Update to latest version
docker-compose pull
docker-compose up -d
```

### Backup Operations
```powershell
# Standard backup (Windows)
.\backup.ps1

# Enhanced backup with verification
.\backup-enhanced.ps1

# Backup with restore testing
.\backup-enhanced.ps1 -TestRestore

# View backup statistics
Get-ChildItem C:\n8n-production\backups

# Manual restore (last resort)
# 1. Stop n8n
docker-compose down
# 2. Copy backup to volume
docker run --rm -v windows-deployment_n8n_data:/volume -v C:\n8n-production\backups:/backup alpine cp /backup/database_backup_YYYY-MM-DD_HH-mm-ss.sqlite /volume/database.sqlite
# 3. Restart
docker-compose up -d
```

---

## 🔧 Common Troubleshooting

### Problem: Can't access n8n web interface

**Quick Fixes:**
```powershell
# 1. Check if containers are running
docker-compose ps

# 2. Check if n8n is responding
curl http://localhost:5678

# 3. Check Docker service
Get-Service docker

# 4. Restart services
docker-compose restart

# 5. Check firewall
Test-NetConnection -ComputerName localhost -Port 5678

# 6. View recent errors
docker-compose logs --tail=50 | Select-String "error"
```

### Problem: Workflows not executing

**Quick Fixes:**
```powershell
# 1. Check container resources
docker stats --no-stream

# 2. Check for errors in logs
docker-compose logs n8n --tail=100

# 3. Verify webhook URLs
# In n8n: Settings → n8n Settings → Editor Base URL
# Should be: https://n8n.improvemyrankings.com

# 4. Test webhook endpoint
curl https://n8n.improvemyrankings.com/webhook-test/test

# 5. Restart n8n
docker-compose restart n8n
```

### Problem: Cloudflare tunnel not working

**Quick Fixes:**
```powershell
# 1. Check cloudflared container
docker-compose logs cloudflared --tail=50

# 2. Verify tunnel configuration
Get-Content C:\n8n-production\cloudflared\config.yml

# 3. Test tunnel connectivity
# Check Cloudflare dashboard: https://dash.cloudflare.com

# 4. Restart tunnel
docker-compose restart cloudflared

# 5. Check tunnel status
docker exec $(docker-compose ps -q cloudflared) cloudflared tunnel info
```

### Problem: Database errors

**Quick Fixes:**
```powershell
# 1. Check database integrity
docker exec -i $(docker-compose ps -q n8n) sqlite3 /home/node/.n8n/database.sqlite "PRAGMA integrity_check;"

# 2. Check disk space
Get-PSDrive C

# 3. Restore from backup
# See "Backup Operations" section above

# 4. Export workflows before any fixes
# In n8n UI: Workflows → Select All → Export

# 5. Check volume mounts
docker volume ls | Select-String "n8n"
```

### Problem: High CPU/Memory usage

**Quick Fixes:**
```powershell
# 1. Check resource usage
docker stats --no-stream

# 2. Check running workflows
# In n8n: Executions → Filter by "Running"

# 3. Increase container limits (edit docker-compose.yml)
# Add under n8n service:
# deploy:
#   resources:
#     limits:
#       memory: 2G
#       cpus: '1.0'

# 4. Restart with new limits
docker-compose down
docker-compose up -d

# 5. Check for stuck executions
# In n8n: Executions → Filter by "Error"
```

---

## 🔐 Security Checklist

### Essential Security Tasks
- [ ] Changed default password in `.env` file
- [ ] `N8N_ENCRYPTION_KEY` is 32+ characters
- [ ] `N8N_SECURE_COOKIE=true` in production
- [ ] Cloudflare SSL is enabled (Full or Full Strict)
- [ ] Basic auth is enabled (`N8N_BASIC_AUTH_ACTIVE=true`)
- [ ] `.env` file is NOT committed to git
- [ ] `cert.pem` is NOT committed to git
- [ ] Regular backups are scheduled
- [ ] Firewall rules are configured
- [ ] OAuth credentials are up to date

---

## 📱 Integration Quick Reference

### HubSpot Integration
```
OAuth Redirect URL: https://n8n.improvemyrankings.com/rest/oauth2-credential/callback
App ID: 15976984
Scopes: contacts, content, automation
```

### AWS SES
```
Region: us-west-2
IAM User: [Your SES user]
Permissions: SES Send, SES Bounce handling
```

### Google OAuth
```
Redirect URIs:
  - https://n8n.improvemyrankings.com/rest/oauth2-credential/callback
  - http://localhost:5678/rest/oauth2-credential/callback

Common Scopes:
  - Gmail: https://www.googleapis.com/auth/gmail.readonly
  - Drive: https://www.googleapis.com/auth/drive.file
```

---

## 🎯 Performance Optimization

### Recommended Settings (.env)
```bash
# Performance
N8N_CONCURRENCY_PRODUCTION_LIMIT=10
EXECUTIONS_DATA_PRUNE=true
EXECUTIONS_DATA_MAX_AGE=336  # 14 days

# Timeouts
N8N_DEFAULT_WEBHOOK_TIMEOUT=120000  # 2 minutes
N8N_TIMEOUT_THRESHOLD=300

# Logging
N8N_LOG_LEVEL=info
N8N_LOG_OUTPUT=console,file

# Timezone
GENERIC_TIMEZONE=America/Los_Angeles
TZ=America/Los_Angeles
```

### Weekly Maintenance Tasks
```powershell
# 1. Check disk space
Get-PSDrive C

# 2. Run health check
.\health-monitor.ps1 -Verbose

# 3. Verify backups
Get-ChildItem C:\n8n-production\backups | Sort-Object LastWriteTime -Descending

# 4. Check for updates
docker images | Select-String "n8n"
# Compare with: https://hub.docker.com/r/n8nio/n8n/tags

# 5. Review failed executions
# In n8n UI: Executions → Filter by "Error"

# 6. Clean up old execution data
# In n8n UI: Settings → Execution Data → Prune

# 7. Export workflows for backup
# In n8n UI: Workflows → Select All → Export
```

---

## 🆘 Emergency Procedures

### Complete System Failure Recovery
```powershell
# 1. Stop all services
docker-compose down

# 2. Verify Docker is running
docker version

# 3. Check disk space
Get-PSDrive C

# 4. Restore from latest backup
.\backup-enhanced.ps1  # Check available backups
# Manually restore (see Backup Operations above)

# 5. Restart services
docker-compose up -d

# 6. Validate deployment
.\validate-deployment.ps1 -PostDeploy

# 7. Test access
curl http://localhost:5678
```

### Lost Admin Password
```powershell
# 1. Stop n8n
docker-compose down

# 2. Update .env file with new password
notepad C:\n8n-production\.env
# Change N8N_BASIC_AUTH_PASSWORD

# 3. Restart
docker-compose up -d
```

### Cloudflare Tunnel Lost Connection
```powershell
# 1. Get new tunnel credentials from Cloudflare dashboard
# https://dash.cloudflare.com → Zero Trust → Networks → Tunnels

# 2. Update config.yml
notepad C:\n8n-production\cloudflared\config.yml

# 3. Replace cert.pem with new certificate
# Download from Cloudflare dashboard

# 4. Restart tunnel
docker-compose restart cloudflared

# 5. Verify
docker-compose logs cloudflared
```

---

## 📞 Support Resources

### Log Locations
```
Windows Event Log: Application → Source: n8n-production
Docker Logs: C:\n8n-production\logs\
Backup Logs: C:\n8n-production\backups\backup.log
Health Monitor Logs: C:\n8n-production\logs\health-monitor.log
```

### Useful Commands for Support
```powershell
# System information
systeminfo | Select-String "OS Name","Total Physical Memory"

# Docker version
docker --version
docker-compose --version

# Container information
docker-compose ps
docker-compose logs --tail=100

# Network information
Get-NetIPAddress | Where-Object {$_.AddressFamily -eq "IPv4"}

# n8n version
docker exec $(docker-compose ps -q n8n) n8n --version

# Disk usage
Get-PSDrive C
Get-ChildItem C:\n8n-production -Recurse | Measure-Object -Property Length -Sum
```

### Documentation Links
- **n8n Docs**: https://docs.n8n.io
- **Docker Docs**: https://docs.docker.com
- **Cloudflare Tunnel Docs**: https://developers.cloudflare.com/cloudflare-one/connections/connect-apps/
- **This Project Docs**: `C:\n8n-production\windows-deployment\README.md`

---

## 💡 Pro Tips

1. **Always validate before deploying:**
   ```powershell
   .\validate-deployment.ps1 -PreDeploy
   ```

2. **Schedule automated health checks:**
   ```powershell
   # Task Scheduler: Run health-monitor.ps1 every 5 minutes
   ```

3. **Keep workflows in version control:**
   - Export workflows regularly
   - Store in `n8n-workflows/` directory
   - Commit to git repository

4. **Monitor backup age:**
   ```powershell
   # Alert if backup older than 48 hours
   $latestBackup = Get-ChildItem C:\n8n-production\backups\*.sqlite | Sort-Object LastWriteTime -Descending | Select-Object -First 1
   $backupAge = (Get-Date) - $latestBackup.LastWriteTime
   if ($backupAge.TotalHours -gt 48) { Write-Warning "Backup is $($backupAge.TotalHours) hours old!" }
   ```

5. **Test restore procedures quarterly:**
   ```powershell
   .\backup-enhanced.ps1 -TestRestore
   ```

---

**Last Updated:** 2025-07-30
**Version:** 2.0 (Enhanced with 80/20 automation tools)

For detailed documentation, see `Docs/` directory.
