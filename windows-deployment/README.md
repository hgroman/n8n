# n8n Windows Server Production Deployment Guide

This guide provides complete instructions for deploying your n8n workflow automation platform to a Windows Server with Docker.

## 📋 Prerequisites

### System Requirements
- Windows Server 2019/2022 or Windows 10/11 Pro
- Minimum 4GB RAM (8GB recommended)
- 50GB available disk space
- Internet connection for Docker image downloads

### Required Software
1. **Docker Desktop for Windows**
   - Download from: https://www.docker.com/products/docker-desktop/
   - Ensure WSL2 backend is enabled
   - Verify installation: `docker --version`

2. **PowerShell 7+** (recommended)
   - Download from: https://github.com/PowerShell/PowerShell/releases
   - Or use Windows PowerShell 5.1 (built-in)

3. **Git for Windows** (optional, for version control)
   - Download from: https://git-scm.com/download/win

## 🚀 Quick Start Deployment

### Step 1: Prepare the Server

1. **Create deployment directory:**
   ```powershell
   New-Item -ItemType Directory -Path "C:\n8n-production" -Force
   Set-Location "C:\n8n-production"
   ```

2. **Copy deployment files:**
   - Copy all files from this `windows-deployment` folder to `C:\n8n-production\`
   - Ensure the following structure:
   ```
   C:\n8n-production\
   ├── docker-compose.yml
   ├── deploy.ps1
   ├── backup.ps1
   ├── install-service.ps1
   ├── .env.example
   ├── cloudflared\
   │   └── config.yml
   └── README.md
   ```

### Step 2: Configure Environment

1. **Create environment file:**
   ```powershell
   Copy-Item ".env.example" ".env"
   notepad .env
   ```

2. **Update the `.env` file with your settings:**
   - Set strong passwords for `N8N_BASIC_AUTH_PASSWORD`
   - Generate a 32-character encryption key for `N8N_ENCRYPTION_KEY`
   - Update domain settings if different from `n8n.improvemyrankings.com`

### Step 3: Configure Cloudflare Tunnel

1. **Update Cloudflare configuration:**
   ```powershell
   notepad "cloudflared\config.yml"
   ```

2. **Replace placeholders:**
   - `your-tunnel-id-here` with your actual Cloudflare tunnel ID
   - Ensure your tunnel certificate (`cert.pem`) is in the `cloudflared` folder

3. **Verify tunnel configuration:**
   - Your tunnel should point to `http://n8n:5678` (internal Docker network)
   - Domain should match your n8n configuration

### Step 4: Deploy n8n

1. **Run the deployment script:**
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   .\deploy.ps1
   ```

2. **For automated deployment (skip prompts):**
   ```powershell
   .\deploy.ps1 -Force
   ```

3. **To skip backup during deployment:**
   ```powershell
   .\deploy.ps1 -SkipBackup
   ```

### Step 5: Install as Windows Service (Optional)

1. **Run PowerShell as Administrator:**
   ```powershell
   # Right-click PowerShell and select "Run as Administrator"
   Set-Location "C:\n8n-production"
   .\install-service.ps1
   ```

2. **Verify service installation:**
   ```powershell
   Get-Service -Name "n8n-production"
   ```

## 🔧 Configuration Details

### Environment Variables

Key environment variables in your `.env` file:

| Variable | Description | Example |
|----------|-------------|---------|
| `N8N_BASIC_AUTH_USER` | Admin username | `admin` |
| `N8N_BASIC_AUTH_PASSWORD` | Admin password | `your_secure_password` |
| `N8N_ENCRYPTION_KEY` | 32-char encryption key | `your_32_character_key_here` |
| `N8N_DOMAIN` | Your domain | `n8n.improvemyrankings.com` |
| `DB_TYPE` | Database type | `sqlite` or `postgresdb` |

### Docker Compose Configuration

The `docker-compose.yml` includes:
- **n8n service**: Main workflow automation platform
- **cloudflared service**: Cloudflare tunnel for secure external access
- **Persistent volumes**: Data persistence across container restarts
- **Network isolation**: Secure internal communication

### Security Considerations

1. **Change default passwords** in `.env` file
2. **Use strong encryption keys** (32 characters minimum)
3. **Enable HTTPS** with `N8N_SECURE_COOKIE=true` in production
4. **Restrict network access** using Windows Firewall
5. **Regular backups** using the provided backup script

## 📊 Management Commands

### Docker Management
```powershell
# View running containers
docker-compose ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Update to latest version
docker-compose pull
docker-compose up -d
```

### Service Management (if installed as service)
```powershell
# Start service
Start-Service -Name "n8n-production"

# Stop service
Stop-Service -Name "n8n-production"

# Restart service
Restart-Service -Name "n8n-production"

# Check service status
Get-Service -Name "n8n-production"
```

### Backup Management
```powershell
# Manual backup
.\backup.ps1

# Schedule automated backups (Task Scheduler)
# Create a scheduled task to run backup.ps1 daily
```

## 🔍 Troubleshooting

### Common Issues

1. **Docker not starting:**
   - Ensure Docker Desktop is running
   - Check WSL2 is enabled
   - Restart Docker service: `Restart-Service docker`

2. **Port conflicts:**
   - Check if port 5678 is in use: `netstat -an | findstr 5678`
   - Change port in `docker-compose.yml` if needed

3. **Cloudflare tunnel issues:**
   - Verify tunnel ID and certificate are correct
   - Check tunnel status in Cloudflare dashboard
   - Review cloudflared logs: `docker-compose logs cloudflared`

4. **Permission errors:**
   - Run PowerShell as Administrator for service operations
   - Check Windows Defender/Antivirus exclusions

### Log Locations

- **Docker logs**: `docker-compose logs`
- **Windows Event Log**: Application log, source "n8n-production"
- **n8n logs**: Available through Docker logs or configured file location

## 🔄 Migration from Development

### Data Migration

1. **Export workflows from development:**
   - Use n8n's export feature to download all workflows
   - Save as JSON files

2. **Copy workflow files:**
   ```powershell
   Copy-Item "path\to\your\workflows\*.json" "C:\n8n-production\n8n-workflows\"
   ```

3. **Import workflows:**
   - Access n8n web interface
   - Import each workflow JSON file

### Credential Migration

1. **AWS SES credentials:**
   - Configure in n8n credentials section
   - Use IAM user with SES permissions (from your memory)

2. **HubSpot credentials:**
   - Set up HubSpot Developer API credentials
   - Configure OAuth or API key authentication

3. **Google OAuth:**
   - Transfer OAuth credentials from development
   - Update redirect URLs for production domain

## 📈 Performance Optimization

### Resource Allocation
```yaml
# Add to docker-compose.yml under n8n service
deploy:
  resources:
    limits:
      memory: 2G
      cpus: '1.0'
    reservations:
      memory: 1G
      cpus: '0.5'
```

### Database Optimization
For high-volume workflows, consider switching to PostgreSQL:
```env
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=your_postgres_host
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n_user
DB_POSTGRESDB_PASSWORD=secure_password
```

## 🛡️ Security Hardening

1. **Windows Firewall:**
   ```powershell
   # Allow only necessary ports
   New-NetFirewallRule -DisplayName "n8n-local" -Direction Inbound -Port 5678 -Protocol TCP -Action Allow
   ```

2. **User Access Control:**
   - Create dedicated service account for n8n
   - Limit administrative access

3. **SSL/TLS:**
   - Cloudflare provides SSL termination
   - Consider additional internal encryption for sensitive data

## 📞 Support

For issues specific to this deployment:
1. Check the troubleshooting section above
2. Review Docker and n8n documentation
3. Check Windows Event Logs for service-related issues
4. Verify Cloudflare tunnel configuration

---

**Deployment completed successfully!** 🎉

Your n8n instance should now be accessible at:
- **Local**: http://localhost:5678
- **Public**: https://n8n.improvemyrankings.com

Remember to:
- ✅ Update default passwords
- ✅ Configure regular backups
- ✅ Monitor system resources
- ✅ Keep Docker images updated
