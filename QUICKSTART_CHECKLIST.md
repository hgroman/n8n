# n8n Fresh Install - Complete Setup Checklist

**Last Updated:** 2025-11-25
**Purpose:** Unified checklist combining knowledge base learnings + CROWS NEST setup requirements
**Estimated Time:** 2-4 hours for complete setup

---

## 📋 Pre-Flight Verification

Before starting, ensure you have:

- [ ] **Docker & Docker Compose** installed and running
- [ ] **Domain name** configured (e.g., n8n.improvemyrankings.com)
- [ ] **Cloudflare account** with domain managed
- [ ] **Google Cloud Console** access
- [ ] **OpenAI account** with billing enabled
- [ ] **AWS account** (if using HubSpot-SES workflow)
- [ ] **HubSpot account** with admin access (if applicable)
- [ ] **Backup of old n8n data** (if migrating)

---

## 🚀 Phase 1: Core Infrastructure Setup

### Step 1: Environment Preparation

**Critical Environment Variables** (from Knowledge Base)

Create `.env` file in your deployment directory:

```bash
# Core n8n Configuration
N8N_PROTOCOL=https
N8N_PORT=5678
N8N_HOST=n8n.improvemyrankings.com
N8N_EDITOR_BASE_URL=https://n8n.improvemyrankings.com
WEBHOOK_URL=https://n8n.improvemyrankings.com

# Security (CHANGE THESE!)
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=YOUR_SECURE_PASSWORD_HERE
N8N_ENCRYPTION_KEY=YOUR_RANDOM_32_CHAR_STRING_HERE

# Cookie Settings
N8N_SECURE_COOKIE=false    # Set to true once HTTPS is working

# Performance
N8N_DEFAULT_WEBHOOK_TIMEOUT=120000
N8N_TIMEOUT_THRESHOLD=300

# Database (SQLite for simplicity, PostgreSQL for production)
DB_TYPE=sqlite
# DB_TYPE=postgresdb  # Uncomment for production
# DB_POSTGRESDB_HOST=postgres
# DB_POSTGRESDB_PORT=5432
# DB_POSTGRESDB_DATABASE=n8n
# DB_POSTGRESDB_USER=n8n
# DB_POSTGRESDB_PASSWORD=secure_db_password

# Logging
N8N_LOG_LEVEL=info          # Change to 'debug' for troubleshooting
N8N_LOG_OUTPUT=console      # Or 'file' for persistent logs
```

**Generate Encryption Key:**
```bash
openssl rand -base64 32
```

**Checklist:**
- [ ] `.env` file created with all variables
- [ ] Secure password set (not "admin"!)
- [ ] Encryption key generated and set
- [ ] Domain name matches your actual domain

---

### Step 2: Docker Compose Configuration

**Critical Volume Setup** (prevents data loss - from Knowledge Base)

```yaml
version: '3.7'

services:
  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_PROTOCOL=${N8N_PROTOCOL}
      - N8N_HOST=${N8N_HOST}
      - N8N_PORT=${N8N_PORT}
      - N8N_EDITOR_BASE_URL=${N8N_EDITOR_BASE_URL}
      - WEBHOOK_URL=${WEBHOOK_URL}
      - N8N_BASIC_AUTH_ACTIVE=${N8N_BASIC_AUTH_ACTIVE}
      - N8N_BASIC_AUTH_USER=${N8N_BASIC_AUTH_USER}
      - N8N_BASIC_AUTH_PASSWORD=${N8N_BASIC_AUTH_PASSWORD}
      - N8N_ENCRYPTION_KEY=${N8N_ENCRYPTION_KEY}
      - N8N_SECURE_COOKIE=${N8N_SECURE_COOKIE}
      - DB_TYPE=${DB_TYPE}
      - N8N_LOG_LEVEL=${N8N_LOG_LEVEL}
    volumes:
      - ./n8n_data:/home/node/.n8n    # CRITICAL: Persistent storage
      - ./backups:/backups
    user: "1000:1000"                  # IMPORTANT: Prevents permission issues

  cloudflared:
    image: cloudflare/cloudflared:latest
    restart: unless-stopped
    command: tunnel run
    volumes:
      - ./cloudflared:/etc/cloudflared  # CRITICAL: Must be directory, not file
    depends_on:
      - n8n

volumes:
  n8n_data:
```

**Common Issues & Fixes:**
- ⚠️ **"Permission denied" errors:** Run `chown -R 1000:1000 ./n8n_data`
- ⚠️ **Data lost after restart:** Verify volume mounts are correct
- ⚠️ **"Is a directory" error:** Check cloudflared volume path

**Checklist:**
- [ ] `docker-compose.yml` created
- [ ] Volumes configured for persistence
- [ ] User ID set to 1000:1000
- [ ] Directory permissions set correctly

---

### Step 3: Cloudflare Tunnel Setup

**Step-by-Step** (from Knowledge Base)

1. **Install Cloudflare CLI** (if not already):
   ```bash
   # macOS
   brew install cloudflare/cloudflare/cloudflared

   # Linux
   wget https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
   sudo dpkg -i cloudflared-linux-amd64.deb
   ```

2. **Authenticate:**
   ```bash
   cloudflared tunnel login
   ```
   - Opens browser, select your domain
   - Certificate saved to `~/.cloudflared/`

3. **Create Tunnel:**
   ```bash
   cloudflared tunnel create n8n-tunnel
   ```
   - Note the **Tunnel ID** (e.g., `400f107a-e096-427a-9f00-e5c66a65be4c`)
   - JSON file created with credentials

4. **Create `cloudflared/config.yml`:**
   ```yaml
   tunnel: YOUR_TUNNEL_ID_HERE
   credentials-file: /etc/cloudflared/YOUR_TUNNEL_ID_HERE.json

   ingress:
     - hostname: n8n.improvemyrankings.com
       service: http://n8n:5678
     - service: http_status:404
   ```

5. **Copy Files to Project:**
   ```bash
   mkdir -p ./cloudflared
   cp ~/.cloudflared/YOUR_TUNNEL_ID.json ./cloudflared/
   # config.yml already created above
   ```

6. **Configure DNS in Cloudflare:**
   ```bash
   cloudflared tunnel route dns n8n-tunnel n8n.improvemyrankings.com
   ```
   - Creates CNAME record automatically

7. **Set SSL Mode in Cloudflare Dashboard:**
   - Go to SSL/TLS → Overview
   - Set to **Full** (or **Full (Strict)** if you have certs)

**Checklist:**
- [ ] Cloudflared installed and authenticated
- [ ] Tunnel created and ID recorded
- [ ] `config.yml` configured with correct hostname
- [ ] Credentials JSON copied to `./cloudflared/`
- [ ] DNS routed via tunnel
- [ ] SSL mode set to Full in Cloudflare
- [ ] Both files are in `./cloudflared/` directory (not just one file)

---

### Step 4: Launch n8n

```bash
# From your deployment directory
docker-compose up -d
```

**Verify Startup:**
```bash
# Check container status
docker-compose ps

# Check logs
docker-compose logs -f n8n
docker-compose logs -f cloudflared

# Should see: "Editor is now accessible via: https://n8n.improvemyrankings.com"
```

**Test Access:**
1. Open: `https://n8n.improvemyrankings.com`
2. You should see basic auth login
3. Login with credentials from `.env`

**Troubleshooting:**
- ⚠️ **Container keeps restarting:** Check logs for permission errors
- ⚠️ **502 Bad Gateway:** Cloudflare tunnel not connected, check `cloudflared` logs
- ⚠️ **Redirect loop:** Check `N8N_SECURE_COOKIE` setting
- ⚠️ **Can't resolve hostname:** DNS not propagated yet (wait 5-10 minutes)

**Checklist:**
- [ ] Containers running (`docker-compose ps` shows "Up")
- [ ] No errors in logs
- [ ] Can access n8n via HTTPS URL
- [ ] Basic auth login works
- [ ] n8n dashboard loads

---

## 🔐 Phase 2: Google Cloud Platform Setup

### Step 5: Enable APIs

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select/Create project: **"n8n-automation"**
3. Navigate to **APIs & Services → Library**
4. Enable these APIs:
   - [ ] **Gmail API**
   - [ ] **Google Drive API**

**Checklist:**
- [ ] Gmail API enabled
- [ ] Google Drive API enabled
- [ ] Project selected correctly

---

### Step 6: OAuth Consent Screen

1. Go to **APIs & Services → OAuth consent screen**
2. **User Type:** External
3. **App Information:**
   - App name: `n8n Automation`
   - User support email: Your email
   - Developer contact: Your email
4. **Scopes:** Click "Add or Remove Scopes"
   - [ ] `https://www.googleapis.com/auth/gmail.modify`
   - [ ] `https://www.googleapis.com/auth/gmail.send`
   - [ ] `https://www.googleapis.com/auth/drive`
   - [ ] `https://www.googleapis.com/auth/drive.file`
5. **Test Users:** Add your Gmail address
6. Save and Continue

**Common Issues:**
- ⚠️ **"Redirect URI mismatch":** Your OAuth consent must use the public domain
- ⚠️ **"This app isn't verified":** Normal for test mode, click "Advanced → Go to app"

**Checklist:**
- [ ] OAuth consent screen configured
- [ ] All 4 scopes added
- [ ] Test user email added
- [ ] Configuration saved

---

### Step 7: Create OAuth Credentials

1. Go to **APIs & Services → Credentials**
2. Click **Create Credentials → OAuth 2.0 Client ID**
3. **Application type:** Web application
4. **Name:** "n8n Integration"
5. **Authorized redirect URIs:** Add:
   ```
   https://n8n.improvemyrankings.com/rest/oauth2-credential/callback
   ```
   ⚠️ **CRITICAL:** Must exactly match your domain!

6. Click **Create**
7. **SAVE IMMEDIATELY:**
   - Copy **Client ID**
   - Copy **Client Secret**

**Checklist:**
- [ ] OAuth Client ID created
- [ ] Redirect URI exactly matches your domain
- [ ] Client ID saved
- [ ] Client Secret saved

---

### Step 8: Gmail Label Setup (for CROWS NEST)

1. Open Gmail
2. Settings → **Labels** tab
3. Create new label: **"Competitor Alerts"**
4. Optional: Create filter to auto-apply label
   - Settings → **Filters and Blocked Addresses**
   - Create filter with criteria (e.g., from competitor domains)
   - Apply label "Competitor Alerts"

**Get Label ID:**
- You'll get this from n8n after connecting Gmail (see Phase 3)

**Checklist:**
- [ ] "Competitor Alerts" label created
- [ ] Filter configured (optional but recommended)

---

### Step 9: Google Drive Folder Setup (for CROWS NEST)

1. Go to [Google Drive](https://drive.google.com)
2. Create folder: **"Crows Nest"**
3. Right-click folder → Share → Copy link
4. Extract **Folder ID** from URL:
   ```
   https://drive.google.com/drive/folders/1HP7Pii6-MrUr5R4Y3GGkIk84ReV6QQIc
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                           This is your folder ID
   ```
5. **Save this ID** - you'll need it when configuring the workflow

**Checklist:**
- [ ] "Crows Nest" folder created
- [ ] Folder ID extracted and saved

---

## 🤖 Phase 3: OpenAI API Setup (for CROWS NEST)

### Step 10: Get OpenAI API Key

1. Go to [OpenAI Platform](https://platform.openai.com)
2. Sign in / Create account
3. Navigate to **API Keys** (left sidebar)
4. Click **Create new secret key**
5. Name: "n8n-crows-nest"
6. **Copy immediately** (won't be shown again!)
7. Verify billing is enabled (Settings → Billing)

**Model Access:**
- CROWS NEST uses: `o4-mini-2025-04-16`
- Alternative: `gpt-4o-mini` or `gpt-4-turbo`

**Checklist:**
- [ ] OpenAI account created
- [ ] API key generated and saved
- [ ] Billing enabled
- [ ] Access to O4-mini verified (or alternative selected)

---

## ⚙️ Phase 4: n8n Credential Configuration

### Step 11: Connect Gmail (in n8n)

1. In n8n, go to **Credentials** (left sidebar)
2. Click **+ Add Credential**
3. Search for: **Gmail OAuth2**
4. Fill in:
   - **Credential Name:** "Gmail account"
   - **Client ID:** (from Step 7)
   - **Client Secret:** (from Step 7)
5. Click **Sign in with Google**
6. Authorize access (click through warnings if in test mode)
7. Click **Save**

**Troubleshooting:**
- ⚠️ **"Redirect URI mismatch":** Double-check OAuth console URI exactly matches `https://n8n.improvemyrankings.com/rest/oauth2-credential/callback`
- ⚠️ **Connection fails:** Check `N8N_SECURE_COOKIE` is false if testing over HTTP

**Checklist:**
- [ ] Gmail credential created
- [ ] Green checkmark showing "Connected"
- [ ] Test by creating a Gmail node and listing labels

---

### Step 12: Connect Google Drive (in n8n)

1. **Credentials → + Add Credential**
2. Search for: **Google Drive OAuth2**
3. Fill in:
   - **Credential Name:** "n8n Google Drive"
   - **Client ID:** (same as Gmail)
   - **Client Secret:** (same as Gmail)
4. Click **Sign in with Google**
5. Authorize access
6. Click **Save**

**Checklist:**
- [ ] Google Drive credential created
- [ ] Green checkmark showing "Connected"

---

### Step 13: Connect OpenAI (in n8n)

1. **Credentials → + Add Credential**
2. Search for: **OpenAI**
3. Fill in:
   - **Credential Name:** "OpenAi account"
   - **API Key:** (from Step 10)
4. Click **Save**

**Checklist:**
- [ ] OpenAI credential created
- [ ] No errors showing

---

## 📥 Phase 5: Workflow Import & Configuration

### Step 14: Import CROWS NEST Workflow

1. In n8n, go to **Workflows** (left sidebar)
2. Click **Import from File**
3. Select: `n8n-Workflows/n8n_CROWS_NEST_07.23.25-3.json`
4. Click **Import**

**Expected:** Workflow opens with red error indicators (credentials not connected yet)

**Checklist:**
- [ ] Workflow imported successfully
- [ ] All nodes visible in canvas
- [ ] Ready to configure credentials

---

### Step 15: Connect Credentials in Workflow

**For EACH node with a credential error (red icon):**

**Gmail Nodes** (3 nodes):
1. Click the node
2. **Credential dropdown → Select "Gmail account"**
3. Save node

**Google Drive Node** (1 node):
1. Click "Competitor Intel File Creator"
2. **Credential dropdown → Select "n8n Google Drive"**
3. Save node

**OpenAI Node** (1 node):
1. Click "AI Competitor Intelligence Analyzer"
2. **Credential dropdown → Select "OpenAi account"**
3. Save node

**Checklist:**
- [ ] All credential errors cleared (no red icons)
- [ ] Each node shows green credential indicator

---

### Step 16: Update Gmail Label ID

**Get Your Label ID:**
1. Add a **Gmail node** to canvas (temporarily)
2. Operation: **Get Many Messages**
3. In **Filters** → **Label IDs**, click dropdown
4. You'll see all your labels with IDs
5. Find **"Competitor Alerts"** and copy its ID (e.g., `Label_1688379935863361814`)

**Update Workflow:**
1. Open **"Get many messages"** node (node #7 in workflow)
2. **Filters** section
3. **Label IDs:** Replace with your label ID
4. Save node

**Checklist:**
- [ ] Label ID obtained
- [ ] "Get many messages" node updated with correct label ID
- [ ] Node saved

---

### Step 17: Update Google Drive Folder ID

1. Open **"Competitor Intel File Creator"** node
2. **Folder ID** field
3. Click dropdown (refreshes to show your folders)
4. Select **"Crows Nest"**
   - OR paste folder ID manually: `1HP7Pii6-MrUr5R4Y3GGkIk84ReV6QQIc`
5. Save node

**Checklist:**
- [ ] Folder ID updated
- [ ] Node saved

---

### Step 18: Verify AI Model Selection

1. Open **"AI Competitor Intelligence Analyzer"** node
2. Check **Model ID:** Should show `O4-mini-2025-04-16`
3. If you don't have access, change to:
   - `gpt-4o-mini` (recommended, cheaper)
   - `gpt-4-turbo` (more powerful, expensive)
4. Save node

**Checklist:**
- [ ] Model verified/updated
- [ ] Node saved

---

### Step 19: Test CROWS NEST Workflow

**Preparation:**
1. Send yourself a test email from a competitor (or forward one)
2. Apply "Competitor Alerts" label in Gmail
3. Mark as **unread**

**Test Run:**
1. In n8n, click workflow name → **Set to Active** (toggle switch)
2. Wait 1 minute (schedule trigger checks every minute)
3. Go to **Executions** (left sidebar)
4. Look for new execution (green = success, red = error)

**Verify Output:**
1. Check Google Drive → "Crows Nest" folder
2. Should see new markdown file with:
   - Email details
   - AI analysis
   - Original content

**Troubleshooting:**
- ⚠️ **No execution appears:** Check label is correct, email is unread
- ⚠️ **Execution fails:** Click execution to see error details
- ⚠️ **"Could not retrieve data":** Email parser issue, check previous node output
- ⚠️ **"Folder not found":** Wrong folder ID or missing Drive permissions

**Checklist:**
- [ ] Workflow activated
- [ ] Test email sent and labeled
- [ ] Execution completed successfully
- [ ] Report generated in Google Drive
- [ ] Email marked as read in Gmail

---

## 🎯 Phase 6: Optional - AWS SES Setup (for HubSpot Workflow)

### Step 20: AWS SES Configuration

**Only if you plan to use "HubSpot to AWS SES" workflow**

1. **AWS Console → SES**
2. **Region:** Select **us-west-2 (Oregon)** (CRITICAL - from Knowledge Base)
3. **Verify Domain:**
   - Verify domain: `lastapple.com`
   - Add DNS records (TXT, CNAME)
4. **Verify Emails:**
   - `hank@lastapple.com`
   - `seo@lastapple.com`
5. **Create Email Template:**
   - Name: `New_email-1752544682` (or your template name)
6. **Request Production Access:**
   - SES → Account Dashboard → Request production access
   - Removes sandbox restrictions

**IAM User Setup:**
1. IAM → Users → Create user: `n8n-ses-sender`
2. Attach policy (inline):
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [{
       "Effect": "Allow",
       "Action": [
         "ses:SendEmail",
         "ses:SendRawEmail",
         "ses:ListTemplates",
         "ses:SendTemplatedEmail"
       ],
       "Resource": "*",
       "Condition": {
         "StringEquals": {
           "aws:RequestedRegion": "us-west-2"
         }
       }
     }]
   }
   ```
3. Create access key → Save **Access Key ID** and **Secret Access Key**

**In n8n:**
1. Create **AWS** credential
2. Use IAM user keys
3. **Region:** us-west-2

**Common Issues (from Knowledge Base):**
- ⚠️ **"Email not verified":** Account still in sandbox mode
- ⚠️ **"Illegal address":** Wrong data format, use `.value` to extract email string
- ⚠️ **"templateData must not be null":** Use `{{ JSON.stringify({}) }}`
- ⚠️ **"Access Denied":** Missing `ses:SendTemplatedEmail` permission

**Checklist:**
- [ ] Region set to us-west-2
- [ ] Domain verified
- [ ] Email addresses verified
- [ ] Email template created
- [ ] Production access granted
- [ ] IAM user created with correct policy
- [ ] n8n AWS credential configured

---

## 🔧 Phase 7: Maintenance & Monitoring

### Step 21: Setup Automated Backups

**Create backup script:**
```bash
#!/bin/bash
# backup-n8n.sh

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_PATH="./n8n_data/database.sqlite"

mkdir -p "$BACKUP_DIR"
cp "$DB_PATH" "$BACKUP_DIR/database_${TIMESTAMP}.sqlite"

# Keep only last 7 days
find "$BACKUP_DIR" -name "database_*.sqlite" -mtime +7 -delete

echo "Backup completed: database_${TIMESTAMP}.sqlite"
```

**Setup cron job:**
```bash
chmod +x backup-n8n.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add line:
0 2 * * * cd /path/to/n8n && ./backup-n8n.sh
```

**Checklist:**
- [ ] Backup script created
- [ ] Script executable
- [ ] Cron job configured (or manual backup schedule)
- [ ] Test backup runs successfully

---

### Step 22: Monitoring Setup

**Health Check:**
```bash
# Add to docker-compose.yml under n8n service:
healthcheck:
  test: ["CMD-SHELL", "wget --spider -q http://localhost:5678/healthz || exit 1"]
  interval: 30s
  timeout: 10s
  retries: 3
```

**View Logs:**
```bash
# Real-time logs
docker-compose logs -f n8n
docker-compose logs -f cloudflared

# Debug mode (if issues)
# Add to .env: N8N_LOG_LEVEL=debug
```

**Monitor Executions:**
- Check **Executions** page daily
- Look for failed executions (red)
- Review execution time trends

**Checklist:**
- [ ] Health check configured
- [ ] Know how to view logs
- [ ] Regular execution monitoring scheduled

---

## ✅ Final Verification Checklist

**Core Infrastructure:**
- [ ] n8n accessible via HTTPS
- [ ] Basic auth working
- [ ] Cloudflare tunnel connected
- [ ] Data persisting across restarts

**Credentials:**
- [ ] Gmail OAuth2 connected (green status)
- [ ] Google Drive OAuth2 connected (green status)
- [ ] OpenAI API key configured
- [ ] AWS credentials configured (if applicable)

**CROWS NEST Workflow:**
- [ ] Workflow imported
- [ ] All nodes configured with credentials
- [ ] Gmail label ID updated
- [ ] Google Drive folder ID updated
- [ ] AI model verified
- [ ] Test execution successful
- [ ] Report generated in Drive
- [ ] Workflow set to Active

**Optional - HubSpot Workflow:**
- [ ] AWS SES configured and verified
- [ ] IAM user created with permissions
- [ ] HubSpot credentials configured
- [ ] Workflow imported and configured

**Maintenance:**
- [ ] Backup system configured
- [ ] Monitoring/logging setup
- [ ] Health checks enabled

---

## 📚 Reference Documentation

**Detailed Guides:**
- Full CROWS NEST setup: `Docs/SETUP_GUIDE_CROWS_NEST.md`
- Troubleshooting: `Docs/Project_Implementation/03_Troubleshooting_Cloudflare_Tunnel_Fix_(Windsurf).md`
- HubSpot Integration: `Docs/Project_Implementation/06_HubSpot_SES_Integration_Playbook_(Windsurf).md`
- Knowledge Base: `windows-deployment/Knowledge Base/`

**Common Commands:**
```bash
# View running containers
docker-compose ps

# View logs
docker-compose logs -f n8n

# Restart n8n
docker-compose restart n8n

# Stop everything
docker-compose down

# Start fresh
docker-compose down && docker-compose up -d

# Backup database
cp ./n8n_data/database.sqlite ./backups/database_$(date +%Y%m%d).sqlite

# Check disk usage
du -sh ./n8n_data
```

**Cost Estimates (Monthly):**
- OpenAI (10 emails/day): ~$9/month
- Google APIs: Free (generous quotas)
- AWS SES (if used): ~$1-5/month
- Cloudflare: Free
- Domain: ~$12/year
- **Total: ~$10-15/month**

---

## 🆘 Quick Troubleshooting

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| 502 Bad Gateway | Cloudflare tunnel down | Check `cloudflared` logs, restart tunnel |
| Permission denied | Volume ownership issue | `chown -R 1000:1000 ./n8n_data` |
| Redirect URI mismatch | OAuth config wrong | Verify exact URL in Google Console |
| Workflow won't activate | Credential errors | Check all nodes for red icons |
| No executions | Trigger not configured | Verify schedule/webhook setup |
| Email not sent | SES sandbox mode | Request production access |
| AI analysis fails | API key invalid | Check OpenAI billing, verify key |
| Data lost on restart | Volume not mounted | Check docker-compose.yml volumes |

---

## 🎉 Success Criteria

You're fully set up when:

✅ n8n accessible via HTTPS with your domain
✅ Can login with basic auth
✅ All credentials show green status
✅ CROWS NEST workflow running and generating reports
✅ Test email processed successfully
✅ Reports appearing in Google Drive
✅ No errors in execution history
✅ Backups configured and tested

---

**Questions? Issues?** Check the detailed setup guides in `Docs/` or review the knowledge base files.

**Next Steps After Setup:**
1. Customize AI prompts in CROWS NEST for your specific needs
2. Set up additional workflows (HubSpot-SES, etc.)
3. Configure monitoring alerts
4. Document any custom configurations
5. Schedule regular backup verification

**Good luck! 🚀**
