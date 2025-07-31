# n8n Windows Server Migration Checklist

## 📋 Pre-Migration Preparation

### ✅ Development Environment Backup
- [ ] Export all n8n workflows as JSON files
- [ ] Document all credential configurations
- [ ] Backup SQLite database using existing backup script
- [ ] List all active integrations (HubSpot, AWS SES, Google OAuth)
- [ ] Document current Cloudflare tunnel configuration

### ✅ Windows Server Preparation
- [ ] Windows Server 2019/2022 or Windows 10/11 Pro installed
- [ ] Minimum 4GB RAM available (8GB recommended)
- [ ] 50GB+ free disk space
- [ ] Administrative access to the server
- [ ] Internet connectivity verified

### ✅ Required Software Installation
- [ ] Docker Desktop for Windows installed and running
- [ ] PowerShell 7+ installed (or Windows PowerShell 5.1)
- [ ] Git for Windows (optional)
- [ ] Text editor (Notepad++, VS Code, etc.)

## 🔧 Migration Process

### ✅ Step 1: File Transfer
- [ ] Copy all files from `windows-deployment/` to `C:\n8n-production\`
- [ ] Verify directory structure is correct
- [ ] Copy workflow JSON files to `C:\n8n-production\n8n-workflows\`
- [ ] Copy Cloudflare tunnel certificate to `C:\n8n-production\cloudflared\cert.pem`

### ✅ Step 2: Configuration
- [ ] Copy `.env.example` to `.env`
- [ ] Update `.env` with production values:
  - [ ] Strong password for `N8N_BASIC_AUTH_PASSWORD`
  - [ ] 32-character `N8N_ENCRYPTION_KEY`
  - [ ] Correct domain name
  - [ ] Database settings (SQLite or PostgreSQL)
- [ ] Update `cloudflared/config.yml` with correct tunnel ID
- [ ] Verify domain DNS points to Cloudflare

### ✅ Step 3: Deployment
- [ ] Open PowerShell as Administrator
- [ ] Navigate to `C:\n8n-production`
- [ ] Set execution policy: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- [ ] Run deployment: `.\deploy.ps1`
- [ ] Verify services are running: `docker-compose ps`
- [ ] Test local access: http://localhost:5678
- [ ] Test public access: https://n8n.improvemyrankings.com

### ✅ Step 4: Service Installation (Optional)
- [ ] Run PowerShell as Administrator
- [ ] Execute: `.\install-service.ps1`
- [ ] Verify service: `Get-Service -Name "n8n-production"`
- [ ] Test service start/stop functionality

## 🔄 Data Migration

### ✅ Workflow Migration
- [ ] Access n8n web interface
- [ ] Import each workflow JSON file individually
- [ ] Verify workflow structure and connections
- [ ] Test workflow execution (dry run)

### ✅ Credential Migration
- [ ] **AWS SES Credentials:**
  - [ ] Create new IAM user or use existing
  - [ ] Apply SES policy from memory (us-west-2 region)
  - [ ] Configure in n8n credentials section
  - [ ] Test email sending capability

- [ ] **HubSpot Credentials:**
  - [ ] Configure HubSpot Developer API credentials
  - [ ] Set up OAuth or API key authentication
  - [ ] Test connection to HubSpot

- [ ] **Google OAuth Credentials:**
  - [ ] Transfer OAuth client credentials
  - [ ] Update redirect URLs for production domain
  - [ ] Test Google service integrations

### ✅ Database Migration
- [ ] If using SQLite: Database will be fresh (workflows imported manually)
- [ ] If migrating existing data: Copy database.sqlite to volume
- [ ] Verify data integrity after migration
- [ ] Test all existing workflows with real data

## 🔍 Post-Migration Verification

### ✅ Functionality Testing
- [ ] Login with admin credentials
- [ ] Create a test workflow
- [ ] Execute existing workflows
- [ ] Test webhook endpoints
- [ ] Verify external integrations work
- [ ] Test email notifications (if configured)

### ✅ Security Verification
- [ ] Confirm HTTPS access works
- [ ] Verify HTTP redirects to HTTPS
- [ ] Test authentication requirements
- [ ] Check Cloudflare security settings
- [ ] Review Windows Firewall configuration

### ✅ Performance Testing
- [ ] Monitor resource usage (CPU, RAM, disk)
- [ ] Test workflow execution times
- [ ] Verify log file rotation
- [ ] Check backup script functionality

## 🛡️ Security Hardening

### ✅ Access Control
- [ ] Change default admin password
- [ ] Create additional user accounts if needed
- [ ] Configure Windows user permissions
- [ ] Set up service account for n8n (if using service)

### ✅ Network Security
- [ ] Configure Windows Firewall rules
- [ ] Restrict unnecessary port access
- [ ] Verify Cloudflare security settings
- [ ] Enable DDoS protection
- [ ] Configure rate limiting

### ✅ Data Protection
- [ ] Set up automated backups
- [ ] Test backup restoration process
- [ ] Configure backup retention policy
- [ ] Encrypt sensitive configuration files
- [ ] Document disaster recovery procedures

## 📊 Monitoring Setup

### ✅ System Monitoring
- [ ] Configure Windows Performance Monitor
- [ ] Set up disk space alerts
- [ ] Monitor Docker container health
- [ ] Configure Windows Event Log monitoring

### ✅ Application Monitoring
- [ ] Enable n8n execution logging
- [ ] Set up workflow failure notifications
- [ ] Configure health check endpoints
- [ ] Monitor integration API limits

### ✅ Backup Monitoring
- [ ] Schedule automated backups
- [ ] Set up backup success/failure notifications
- [ ] Test backup restoration process
- [ ] Document backup procedures

## 🔄 Maintenance Procedures

### ✅ Regular Maintenance
- [ ] Document update procedures
- [ ] Schedule regular security updates
- [ ] Plan for Docker image updates
- [ ] Create maintenance windows
- [ ] Document rollback procedures

### ✅ Documentation
- [ ] Update network documentation
- [ ] Document all credentials and their locations
- [ ] Create troubleshooting runbook
- [ ] Document contact information for support
- [ ] Create user training materials

## ✅ Final Verification

### ✅ Production Readiness
- [ ] All workflows imported and tested
- [ ] All integrations working correctly
- [ ] Monitoring and alerting configured
- [ ] Backup and recovery tested
- [ ] Documentation completed
- [ ] Team trained on new environment

### ✅ Go-Live Checklist
- [ ] DNS updated to point to new server (if applicable)
- [ ] Old development server documented for decommission
- [ ] Stakeholders notified of migration completion
- [ ] Support procedures activated
- [ ] Performance baseline established

---

## 🆘 Emergency Contacts

**In case of issues during migration:**

1. **Docker Issues:**
   - Check Docker Desktop status
   - Restart Docker service
   - Review Docker logs

2. **Network Issues:**
   - Verify Cloudflare tunnel status
   - Check DNS resolution
   - Test local connectivity

3. **Application Issues:**
   - Check n8n logs: `docker-compose logs n8n`
   - Verify environment configuration
   - Test database connectivity

4. **Service Issues:**
   - Check Windows Event Log
   - Verify service permissions
   - Test manual startup

---

**Migration Status:** ⏳ In Progress / ✅ Complete

**Migration Date:** _______________

**Migrated By:** _______________

**Verified By:** _______________
