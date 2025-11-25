# n8n Setup: Zero-Gap Layered Validation Guide

**Purpose:** Bulletproof setup process with ZERO assumptions and ZERO gaps.
**Rule:** DO NOT proceed to next layer until current layer is 100% verified.

---

## 🎯 Layer Architecture

```
Layer 0: Prerequisites (OS/Network)
    ↓ VERIFY before proceeding
Layer 1: Cloudflare Tunnel (DNS/Routing)
    ↓ VERIFY before proceeding
Layer 2: Docker (Containers/Networking)
    ↓ VERIFY before proceeding
Layer 3: Application (Credentials/Workflows)
    ↓ VERIFY before proceeding
Layer 4: Testing (End-to-End)
```

**CRITICAL RULE:** Each layer has a **GATE**. You MUST pass the gate before moving forward.

---

## 📋 LAYER 0: Prerequisites & Environment

### What This Layer Does
Ensures your OS, network, and tools are ready. Nothing Docker-related yet.

### Requirements Checklist

#### For Mac:
- [ ] macOS version: 10.15+ (run: `sw_vers`)
- [ ] Docker Desktop installed: 4.0+ (run: `docker --version`)
- [ ] Docker Desktop is **RUNNING** (check menu bar icon)
- [ ] Homebrew installed (run: `brew --version`)
- [ ] Terminal access (duh)
- [ ] Internet connection working
- [ ] Port 5678 not in use (run: `lsof -i :5678` - should be empty)

#### For Windows:
- [ ] Windows 10/11 Pro (required for Docker Desktop)
- [ ] Docker Desktop installed: 4.0+
- [ ] Docker Desktop is **RUNNING** (check system tray)
- [ ] WSL2 installed and enabled
- [ ] PowerShell access
- [ ] Internet connection working
- [ ] Port 5678 not in use (run: `netstat -an | findstr :5678` - should be empty)

#### Universal Requirements:
- [ ] Cloudflare account exists
- [ ] Domain added to Cloudflare (e.g., improvemyrankings.com)
- [ ] You have admin access to Cloudflare account
- [ ] cloudflared CLI installed

### Installation Steps (If Missing)

#### Install cloudflared (Mac):
```bash
brew install cloudflare/cloudflare/cloudflared
cloudflared --version  # Verify
```

#### Install cloudflared (Windows):
```powershell
# Download from: https://github.com/cloudflare/cloudflared/releases
# Or use winget:
winget install Cloudflare.cloudflared
cloudflared --version  # Verify
```

### 🚪 GATE 0: Verification Commands

**Run these commands. ALL must pass before proceeding.**

```bash
# Check Docker is running
docker ps
# Expected: Table showing containers (may be empty, but shouldn't error)

# Check Docker can pull images
docker pull hello-world
docker run --rm hello-world
# Expected: "Hello from Docker!" message

# Check cloudflared is installed
cloudflared --version
# Expected: Version number (e.g., "cloudflared version 2024.x.x")

# Check Cloudflare login works
cloudflared tunnel login
# Expected: Browser opens, you can select domain, cert saved to ~/.cloudflared/
```

**STOP HERE if ANY command fails. Fix before proceeding.**

---

## 📋 LAYER 1: Cloudflare Tunnel (DNS/Routing)

### What This Layer Does
Sets up Cloudflare Tunnel infrastructure. NO Docker yet - just DNS and tunnel registration.

### Your Tunnel Architecture

You have **3 tunnels** mapped to **3 environments**:

| Environment | Subdomain | Tunnel ID | CNAME Target |
|-------------|-----------|-----------|--------------|
| Development | n8n-dev | `b8e14e7d-03b9-4f27-9763-1862fe4c873a` | `b8e14e7d-03b9-4f27-9763-1862fe4c873a.cfargotunnel.com` |
| Production (Main) | n8n | `400f107a-e096-427a-9f00-e5c66a65be4c` | `400f107a-e096-427a-9f00-e5c66a65be4c.cfargotunnel.com` |
| Production (Alternate) | n8n-prod | `6f474db4-a5a7-48e4-aed7-ed8c9d5bb92a` | `6f474db4-a5a7-48e4-aed7-ed8c9d5bb92a.cfargotunnel.com` |

### Step 1.1: Verify Tunnel Exists

**For EACH tunnel you plan to use:**

```bash
# List all your tunnels
cloudflared tunnel list

# Expected output should show:
# ID: b8e14e7d-03b9-4f27-9763-1862fe4c873a  NAME: [tunnel-name]
# ID: 400f107a-e096-427a-9f00-e5c66a65be4c  NAME: [tunnel-name]
# ID: 6f474db4-a5a7-48e4-aed7-ed8c9d5bb92a  NAME: [tunnel-name]
```

**If tunnel doesn't exist, create it:**
```bash
# Example for creating dev tunnel (ONLY if it doesn't exist)
cloudflared tunnel create n8n-dev-mac
# Save the tunnel ID it gives you
```

**CRITICAL:** Each physical machine should have its OWN tunnel. Don't reuse tunnel IDs across machines.

### Step 1.2: Verify DNS Records in Cloudflare

**Login to Cloudflare Dashboard → DNS → Records**

Verify these CNAME records exist:

```
Type: CNAME
Name: n8n-dev
Target: b8e14e7d-03b9-4f27-9763-1862fe4c873a.cfargotunnel.com
Proxy: Enabled (orange cloud)

Type: CNAME
Name: n8n
Target: 400f107a-e096-427a-9f00-e5c66a65be4c.cfargotunnel.com
Proxy: Enabled (orange cloud)

Type: CNAME
Name: n8n-prod
Target: 6f474db4-a5a7-48e4-aed7-ed8c9d5bb92a.cfargotunnel.com
Proxy: Enabled (orange cloud)
```

**If missing, add them:**
```bash
# Or add via CLI (example for dev):
cloudflared tunnel route dns b8e14e7d-03b9-4f27-9763-1862fe4c873a n8n-dev.improvemyrankings.com
```

### Step 1.3: Verify Tunnel Configuration File Exists

**Check for the tunnel credentials JSON:**

```bash
# Mac
ls -la ~/.cloudflared/

# Expected files:
# - cert.pem (your Cloudflare certificate)
# - b8e14e7d-03b9-4f27-9763-1862fe4c873a.json (tunnel credentials)
# - 400f107a-e096-427a-9f00-e5c66a65be4c.json (tunnel credentials)
# - 6f474db4-a5a7-48e4-aed7-ed8c9d5bb92a.json (tunnel credentials)
# - config.yml (tunnel configuration - we'll create this next)
```

**If JSON files are missing:** You need to recreate the tunnel or copy from another machine.

### Step 1.4: Determine Which Environment You're Setting Up

**CHOOSE ONE for this setup session:**

- [ ] **Development** (n8n-dev) - Tunnel ID: `b8e14e7d-03b9-4f27-9763-1862fe4c873a`
- [ ] **Production** (n8n) - Tunnel ID: `400f107a-e096-427a-9f00-e5c66a65be4c`
- [ ] **Production Alt** (n8n-prod) - Tunnel ID: `6f474db4-a5a7-48e4-aed7-ed8c9d5bb92a`

**For this guide, we'll use examples for "Production (n8n)" - Tunnel ID: `400f107a-e096-427a-9f00-e5c66a65be4c`**

**Replace with your chosen tunnel ID throughout.**

### 🚪 GATE 1: Verification Commands

**Before proceeding, verify:**

```bash
# 1. Tunnel exists
cloudflared tunnel list | grep 400f107a-e096-427a-9f00-e5c66a65be4c
# Expected: Shows tunnel with this ID

# 2. Credentials file exists
ls ~/.cloudflared/400f107a-e096-427a-9f00-e5c66a65be4c.json
# Expected: File exists (no error)

# 3. DNS propagated (wait 2 minutes after creating DNS record)
nslookup n8n.improvemyrankings.com
# Expected: Returns Cloudflare IP (104.x.x.x or 172.x.x.x range)

# 4. DNS CNAME check
dig n8n.improvemyrankings.com CNAME +short
# Expected: 400f107a-e096-427a-9f00-e5c66a65be4c.cfargotunnel.com
```

**STOP HERE if ANY verification fails.**

---

## 📋 LAYER 2: Docker (Containers/Networking)

### What This Layer Does
Sets up Docker containers with PROPER networking. This is where the 3am nightmare happened.

### Critical Understanding

**The problem that caused 3.5 hours of pain:**
- Docker containers must be on the **same network**
- Containers must have **DNS aliases** for hostname resolution
- cloudflared needs to resolve `n8n` as a hostname
- If this isn't set up correctly: Error 502, Error 1033, "no such host"

**We will set this up correctly from the start.**

### Step 2.1: Choose Your Docker Compose Location

**CRITICAL DECISION:** Where is your docker-compose.yml?

Your project has multiple:
- `n8n-local/docker-compose.yml` (for local/Mac development)
- `windows-deployment/docker-compose.yml` (for Windows production)

**For Mac setup, use: `n8n-local/docker-compose.yml`**

```bash
# Navigate to it
cd ~/n8n/n8n-local  # Or wherever your repo is cloned

# Verify file exists
ls -la docker-compose.yml
```

### Step 2.2: Create/Verify Environment Variables

**Create `.env` file in the same directory as docker-compose.yml:**

```bash
# Create .env file
cat > .env << 'EOF'
# Domain Configuration
N8N_DOMAIN=n8n.improvemyrankings.com
N8N_PROTOCOL=https
N8N_PORT=5678

# URLs (CRITICAL - must match Cloudflare DNS)
N8N_HOST=n8n.improvemyrankings.com
N8N_EDITOR_BASE_URL=https://n8n.improvemyrankings.com
WEBHOOK_URL=https://n8n.improvemyrankings.com

# Security
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=admin
N8N_BASIC_AUTH_PASSWORD=CHANGE_ME_TO_SECURE_PASSWORD
N8N_ENCRYPTION_KEY=GENERATE_32_CHAR_KEY_HERE

# Cookies (set to false initially, true after HTTPS works)
N8N_SECURE_COOKIE=false

# Database
DB_TYPE=sqlite

# Logging
N8N_LOG_LEVEL=info
EOF

# Generate encryption key
openssl rand -base64 32
# Copy output and replace N8N_ENCRYPTION_KEY value in .env

# Edit .env to set your password and key
nano .env  # or vim, code, etc.
```

**VERIFY:**
```bash
# Check .env exists
cat .env

# Verify all values are set (no "CHANGE_ME" or "GENERATE" placeholders)
grep "CHANGE_ME" .env  # Should return nothing
grep "GENERATE" .env   # Should return nothing
```

### Step 2.3: Create Cloudflare Tunnel Config

**Create config.yml for your tunnel:**

**CRITICAL:** This file goes in `~/.cloudflared/config.yml` on your Mac.

```bash
# Create/edit config.yml
cat > ~/.cloudflared/config.yml << 'EOF'
tunnel: 400f107a-e096-427a-9f00-e5c66a65be4c
credentials-file: /etc/cloudflared/400f107a-e096-427a-9f00-e5c66a65be4c.json

ingress:
  - hostname: n8n.improvemyrankings.com
    service: http://n8n:5678
  - service: http_status:404
EOF
```

**CRITICAL DETAILS:**
- `tunnel:` - Your tunnel ID (replace with yours)
- `credentials-file:` - Path **INSIDE the Docker container** (not your Mac path)
- `hostname:` - Must exactly match DNS record
- `service: http://n8n:5678` - Uses container NAME `n8n` (not localhost!)

**VERIFY:**
```bash
cat ~/.cloudflared/config.yml

# Check tunnel ID matches
grep "tunnel:" ~/.cloudflared/config.yml
# Should show: tunnel: 400f107a-e096-427a-9f00-e5c66a65be4c

# Check hostname matches
grep "hostname:" ~/.cloudflared/config.yml
# Should show: hostname: n8n.improvemyrankings.com
```

### Step 2.4: Create/Verify Docker Compose File

**The CORRECT docker-compose.yml with proper networking:**

```bash
cd ~/n8n/n8n-local

# Create docker-compose.yml (or verify existing matches this)
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  n8n:
    image: n8nio/n8n:latest
    container_name: n8n
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
      - n8n_data:/home/node/.n8n
    networks:
      n8n_network:
        aliases:
          - n8n

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    restart: unless-stopped
    command: tunnel run
    volumes:
      - ~/.cloudflared:/etc/cloudflared:ro
    depends_on:
      - n8n
    networks:
      - n8n_network

networks:
  n8n_network:
    name: n8n_network
    driver: bridge

volumes:
  n8n_data:
    driver: local
EOF
```

**CRITICAL SECTIONS EXPLAINED:**

1. **Networks section (bottom):**
   ```yaml
   networks:
     n8n_network:
       name: n8n_network
       driver: bridge
   ```
   - Creates a custom bridge network named `n8n_network`
   - Both containers will be on this network

2. **n8n service networks:**
   ```yaml
   networks:
     n8n_network:
       aliases:
         - n8n
   ```
   - Joins the `n8n_network`
   - **CRITICAL:** `aliases: - n8n` means this container is resolvable as `n8n` hostname
   - This is what cloudflared uses in `service: http://n8n:5678`

3. **cloudflared service networks:**
   ```yaml
   networks:
     - n8n_network
   ```
   - Joins the same network
   - Can now resolve `n8n` hostname via Docker DNS

**VERIFY:**
```bash
# Check docker-compose.yml syntax
docker-compose config
# Should show parsed YAML without errors

# Check networks are defined
docker-compose config | grep -A 5 "networks:"
# Should show n8n_network defined

# Check n8n has alias
docker-compose config | grep -A 3 "n8n:"
# Should show aliases section under networks
```

### Step 2.5: Stop Any Existing Containers

**CRITICAL:** Stop any running n8n or cloudflared containers from previous attempts.

```bash
# Check what's running
docker ps

# If you see n8n or cloudflared containers, stop them:
docker stop n8n cloudflared 2>/dev/null || true
docker rm n8n cloudflared 2>/dev/null || true

# Alternatively, if they were started with compose:
docker-compose down

# Verify nothing is running
docker ps | grep -E "n8n|cloudflared"
# Should return nothing
```

### Step 2.6: Start Containers

```bash
cd ~/n8n/n8n-local

# Start in detached mode
docker-compose up -d

# Check both containers started
docker-compose ps
# Should show:
# n8n          running
# cloudflared  running
```

### 🚪 GATE 2: Docker Verification Commands

**Run ALL these checks. ALL must pass.**

#### Check 1: Containers Running
```bash
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Expected:
# n8n          Up X minutes    0.0.0.0:5678->5678/tcp
# cloudflared  Up X minutes
```

#### Check 2: Both on Same Network
```bash
docker ps --format "table {{.Names}}\t{{.Networks}}"

# Expected (BOTH must show n8n_network):
# n8n          n8n_network
# cloudflared  n8n_network
```

#### Check 3: n8n Has DNS Alias
```bash
docker inspect n8n -f '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{.Aliases}}{{end}}'

# Expected output must include:
# n8n_network: [n8n ...]
```

#### Check 4: cloudflared Can Resolve n8n
```bash
docker exec cloudflared nslookup n8n

# Expected: Shows IP address (likely 172.x.x.x)
# If error "can't resolve": NETWORKING IS BROKEN - DO NOT PROCEED
```

#### Check 5: n8n Is Responding Locally
```bash
curl -I http://localhost:5678

# Expected: HTTP/1.1 200 OK or 401 Unauthorized (auth working)
# If connection refused: n8n not running properly
```

#### Check 6: Tunnel Connected to Cloudflare
```bash
docker logs cloudflared --tail 30

# Look for line containing:
# "Registered tunnel connection"
# or "Connection ... registered"

# If you see "no such host" or "connection refused": NETWORKING BROKEN
```

#### Check 7: n8n Logs Show Ready
```bash
docker logs n8n --tail 30

# Look for:
# "n8n ready on ::, port 5678"
# or "Editor is now accessible"
```

#### Check 8: Public DNS Resolves
```bash
nslookup n8n.improvemyrankings.com

# Expected: Returns Cloudflare IP (104.x.x.x)
```

#### Check 9: Public HTTPS Access
```bash
curl -I https://n8n.improvemyrankings.com

# Expected: HTTP/2 200 or HTTP/2 401 (both mean it's working)
# If 502, 503, 1033: TUNNEL NOT REACHING N8N
```

#### Check 10: Browser Access
```
Open: https://n8n.improvemyrankings.com

Expected: n8n login page OR basic auth prompt
If Error 502/1033: STOP - networking broken
```

### Troubleshooting Layer 2 (If Gate 2 Fails)

**If Check 4 fails (cloudflared can't resolve n8n):**
```bash
# Manual fix (the 3am solution):
docker network connect --alias n8n n8n_network n8n

# Then recheck:
docker exec cloudflared nslookup n8n
```

**If Check 6 fails (tunnel not connecting):**
```bash
# Check config.yml exists in container
docker exec cloudflared ls /etc/cloudflared/
# Should show: config.yml and [tunnel-id].json

# Check config.yml contents
docker exec cloudflared cat /etc/cloudflared/config.yml
# Verify tunnel ID and hostname match your setup
```

**If Check 9 fails (502/1033 errors):**
```bash
# Restart cloudflared
docker-compose restart cloudflared

# Wait 30 seconds
sleep 30

# Recheck
curl -I https://n8n.improvemyrankings.com
```

**STOP HERE if any check fails. Fix before proceeding to Layer 3.**

---

## 📋 LAYER 3: Application (Credentials & Workflows)

### What This Layer Does
Sets up credentials in n8n and imports workflows. Docker is working, n8n is accessible.

### Prerequisites for This Layer

**VERIFY these are true:**
- [ ] You can access https://n8n.improvemyrankings.com in browser
- [ ] You can login with basic auth (admin/your-password)
- [ ] n8n dashboard loads without errors

### Step 3.1: Google Cloud Console Setup

#### 3.1.1: Create Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Click "Select a project" → "New Project"
3. **Project name:** `n8n-automation`
4. Click "Create"
5. Wait for project creation (30 seconds)
6. **Verify:** You see "n8n-automation" in project selector

#### 3.1.2: Enable APIs

1. In Google Cloud Console, ensure `n8n-automation` project is selected
2. Go to **APIs & Services** → **Library**
3. Search for "Gmail API"
   - Click "Gmail API"
   - Click "Enable"
   - Wait for confirmation (10 seconds)
4. Click "Library" again
5. Search for "Google Drive API"
   - Click "Google Drive API"
   - Click "Enable"
   - Wait for confirmation (10 seconds)

**VERIFY:**
```
Go to: APIs & Services → Enabled APIs & Services
Should see:
- Gmail API (Enabled)
- Google Drive API (Enabled)
```

#### 3.1.3: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. **User Type:** Select "External"
3. Click "Create"
4. **Fill in:**
   - App name: `n8n Automation`
   - User support email: Your email
   - Developer contact email: Your email
5. Click "Save and Continue"
6. **Scopes page:**
   - Click "Add or Remove Scopes"
   - Search and add these scopes:
     - `https://www.googleapis.com/auth/gmail.modify`
     - `https://www.googleapis.com/auth/gmail.send`
     - `https://www.googleapis.com/auth/drive`
     - `https://www.googleapis.com/auth/drive.file`
   - Click "Update"
   - Click "Save and Continue"
7. **Test users page:**
   - Click "Add Users"
   - Enter your Gmail address
   - Click "Add"
   - Click "Save and Continue"
8. **Summary page:**
   - Click "Back to Dashboard"

**VERIFY:**
```
OAuth consent screen shows:
- Status: Testing
- User type: External
- Scopes: 4 scopes added
- Test users: Your email listed
```

#### 3.1.4: Create OAuth Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client ID**
3. **Application type:** Web application
4. **Name:** `n8n Integration`
5. **Authorized redirect URIs:**
   - Click "Add URI"
   - Enter: `https://n8n.improvemyrankings.com/rest/oauth2-credential/callback`
   - **CRITICAL:** Must be exact, no trailing slash
6. Click "Create"
7. **SAVE IMMEDIATELY:**
   - Copy **Client ID** (looks like: `123456789-abc.apps.googleusercontent.com`)
   - Copy **Client Secret** (looks like: `GOCSPX-abc123...`)
   - Store in password manager or secure note

**VERIFY:**
```
You have saved:
- Client ID: [value]
- Client Secret: [value]
```

### Step 3.2: OpenAI API Setup

1. Go to [OpenAI Platform](https://platform.openai.com)
2. Sign in / Create account
3. Navigate to **API Keys** (left sidebar)
4. Click **Create new secret key**
5. **Name:** `n8n-crows-nest`
6. Click "Create"
7. **Copy immediately** (shown only once)
8. Store in password manager

**VERIFY:**
```
Go to: Settings → Billing
Check: Billing is enabled (card added)
```

### Step 3.3: Gmail & Drive Preparation

#### Create Gmail Label

1. Open Gmail
2. Click Settings gear → "See all settings"
3. Go to **Labels** tab
4. Scroll down, click "Create new label"
5. **Label name:** `Competitor Alerts`
6. Click "Create"

**VERIFY:**
```
Labels section shows: Competitor Alerts
```

#### Create Google Drive Folder

1. Go to [Google Drive](https://drive.google.com)
2. Click "New" → "Folder"
3. **Name:** `Crows Nest`
4. Click "Create"
5. Right-click folder → "Get link" → "Copy link"
6. Extract folder ID from URL:
   ```
   https://drive.google.com/drive/folders/1HP7Pii6-MrUr5R4Y3GGkIk84ReV6QQIc
                                           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                           This is the folder ID
   ```
7. **Save folder ID:** `1HP7Pii6-MrUr5R4Y3GGkIk84ReV6QQIc`

**VERIFY:**
```
Drive folder exists: Crows Nest
Folder ID saved: [your ID]
```

### Step 3.4: Create Credentials in n8n

#### Gmail OAuth2 Credential

1. In n8n, go to **Credentials** (left sidebar)
2. Click **+ Add Credential**
3. Search: `Gmail OAuth2`
4. Click **Gmail OAuth2**
5. **Fill in:**
   - Credential name: `Gmail account`
   - Client ID: [paste from Step 3.1.4]
   - Client Secret: [paste from Step 3.1.4]
6. Click **Sign in with Google**
7. **CRITICAL:** Browser opens, you'll see "This app isn't verified"
   - Click "Advanced"
   - Click "Go to n8n Automation (unsafe)" (it's safe, it's yours)
8. **Grant permissions** (check all boxes)
9. Click "Allow"
10. Browser returns to n8n, shows "Connected"
11. Click **Save**

**VERIFY:**
```
In n8n Credentials page:
- Gmail account credential shows green checkmark
- Status: Connected
```

#### Google Drive OAuth2 Credential

1. **Credentials** → **+ Add Credential**
2. Search: `Google Drive OAuth2`
3. Click **Google Drive OAuth2 API**
4. **Fill in:**
   - Credential name: `Google Drive account`
   - Client ID: [same as Gmail]
   - Client Secret: [same as Gmail]
5. Click **Sign in with Google**
6. Grant permissions (same process as Gmail)
7. Click **Save**

**VERIFY:**
```
Google Drive account credential shows green checkmark
```

#### OpenAI Credential

1. **Credentials** → **+ Add Credential**
2. Search: `OpenAI`
3. Click **OpenAI API**
4. **Fill in:**
   - Credential name: `OpenAI account`
   - API Key: [paste from Step 3.2]
5. Click **Save**

**VERIFY:**
```
OpenAI account credential saved (no error)
```

### 🚪 GATE 3: Credentials Verification

**Before importing workflows, verify:**

```
In n8n → Credentials page:
- [ ] Gmail OAuth2: Green checkmark, "Connected"
- [ ] Google Drive OAuth2: Green checkmark, "Connected"
- [ ] OpenAI API: Saved, no errors
```

**Test Credentials:**

1. Go to **Workflows** → "Create a new workflow"
2. Add **Gmail** node
3. Operation: "Get Many Messages"
4. Credential: Select "Gmail account"
5. Click "Test step"
6. **Expected:** Returns email list (even if empty)
7. **If error:** Credential is broken, fix before proceeding

**Do NOT proceed to Step 3.5 until credentials work.**

---

### Step 3.5: Import CROWS NEST Workflow

1. In n8n, go to **Workflows**
2. Click **Import from File**
3. Navigate to: `~/n8n/n8n-Workflows/n8n_CROWS_NEST_07.23.25-3.json`
4. Select file
5. Click **Import**
6. Workflow opens in editor

**VERIFY:**
```
Workflow canvas shows 8 nodes:
- Schedule Trigger
- Get many messages (Gmail)
- Get a message (Gmail)
- Email Parser & Domain Extractor (Code)
- AI Competitor Intelligence Analyzer (OpenAI)
- Data Merger & AI Integration (Code)
- Competitor Intel File Creator (Google Drive)
- Mark a message as read (Gmail)
```

### Step 3.6: Connect Credentials to Nodes

**For EACH node with credential dropdown:**

#### Node 1: Get many messages (Gmail)
- Click node
- **Credential:** Select "Gmail account"
- Click outside to save

#### Node 2: Get a message (Gmail)
- Click node
- **Credential:** Select "Gmail account"
- Click outside to save

#### Node 3: AI Competitor Intelligence Analyzer (OpenAI)
- Click node
- **Credential:** Select "OpenAI account"
- Click outside to save

#### Node 4: Competitor Intel File Creator (Google Drive)
- Click node
- **Credential:** Select "Google Drive account"
- Click outside to save

#### Node 5: Mark a message as read (Gmail)
- Click node
- **Credential:** Select "Gmail account"
- Click outside to save

**VERIFY:**
```
All nodes show green credential indicators
No red error icons on any node
```

### Step 3.7: Update Gmail Label ID

#### Get Your Label ID:

1. **Temporarily add a Gmail node** to canvas (we'll delete it)
2. **Operation:** Get Many Messages
3. **Filters:** Click "Add Filter"
4. **Label IDs:** Click the dropdown
5. You'll see all your labels with IDs like:
   ```
   Competitor Alerts (Label_1688379935863361814)
   ```
6. **Copy the ID:** `Label_1688379935863361814`
7. Delete the temporary node

#### Update Workflow:

1. Click the **"Get many messages"** node (node #7 in workflow)
2. Find **Filters** section
3. **Label IDs:** Should show old label ID
4. Click the dropdown
5. Select **"Competitor Alerts"** (your label)
6. OR manually paste your label ID
7. Click outside to save

**VERIFY:**
```
"Get many messages" node:
- Label IDs shows YOUR label ID
- No errors
```

### Step 3.8: Update Google Drive Folder ID

1. Click **"Competitor Intel File Creator"** node
2. Find **Folder ID** field
3. Click the dropdown (it will refresh and show your folders)
4. Select **"Crows Nest"**
5. OR manually paste your folder ID: `1HP7Pii6-MrUr5R4Y3GGkIk84ReV6QQIc`
6. Click outside to save

**VERIFY:**
```
"Competitor Intel File Creator" node:
- Folder ID shows YOUR folder ID
- No errors
```

### Step 3.9: Verify AI Model

1. Click **"AI Competitor Intelligence Analyzer"** node
2. Check **Model ID** field
3. Should show: `o4-mini-2025-04-16`
4. If you don't have access to this model:
   - Change to: `gpt-4o-mini` (recommended)
   - Or: `gpt-4-turbo`
5. Click outside to save

**VERIFY:**
```
AI node shows valid model selection
No errors
```

### Step 3.10: Save Workflow

1. Click workflow name (top left) → Rename to: `CROWS NEST - Production`
2. Click **Save** (top right)
3. **DO NOT activate yet** (we'll test first)

**VERIFY:**
```
Workflow saved (no unsaved changes indicator)
Workflow shows as inactive (toggle is OFF)
```

### 🚪 GATE 3: Application Layer Verification

**Before testing, verify:**

```
In n8n:
- [ ] All 3 credentials created and connected
- [ ] CROWS NEST workflow imported
- [ ] All nodes have green credential indicators
- [ ] Gmail label ID updated to YOUR label
- [ ] Drive folder ID updated to YOUR folder
- [ ] AI model verified/changed if needed
- [ ] Workflow saved
```

**STOP HERE if anything is missing or broken.**

---

## 📋 LAYER 4: End-to-End Testing

### What This Layer Does
Tests the complete flow from email → AI analysis → Drive report.

### Step 4.1: Prepare Test Email

1. **Send yourself an email** from any account
   - Or forward a competitor email to yourself
2. **Subject:** `Test - Competitor Analysis`
3. **Body:** Some text about a product/service/pricing

### Step 4.2: Label and Mark Unread

1. Open Gmail
2. Find the test email
3. **Apply label:** "Competitor Alerts"
4. **Mark as unread** (if you read it)

**VERIFY:**
```
Gmail shows:
- Email has "Competitor Alerts" label
- Email is unread (bold)
```

### Step 4.3: Manual Test Workflow (Before Activating)

1. In n8n, open CROWS NEST workflow
2. Click **"Execute Workflow"** button (top right)
3. Watch nodes light up one by one
4. **Expected flow:**
   - Schedule Trigger (manual)
   - Get many messages (finds your email)
   - Get a message (fetches full email)
   - Email Parser (extracts text)
   - AI Analyzer (calls OpenAI)
   - Data Merger (combines data)
   - Competitor Intel File Creator (creates Drive file)
   - Mark as read (marks email read)

**VERIFY at each step:**
- All nodes show green checkmarks
- No red error icons
- Click each node to see output data

### Step 4.4: Check Output

#### Check Google Drive:

1. Go to [Google Drive](https://drive.google.com)
2. Open "Crows Nest" folder
3. **Expected:** New markdown file with timestamp filename
   - Example: `2025-11-25_15-30_Test-Competitor-Analysis.md`
4. Open file
5. **Verify content includes:**
   - YAML frontmatter (tags, date, sender info)
   - Email details section
   - AI competitive analysis section
   - Original email content
   - Processing metadata

#### Check Gmail:

1. Go to Gmail
2. Find the test email
3. **Expected:** Email is now marked as read

### Step 4.5: Activate Workflow

**If manual test passed:**

1. In n8n, CROWS NEST workflow
2. Toggle **Active** switch (top right) to ON
3. Workflow is now running every 1 minute

**VERIFY:**
```
Workflow shows "Active" (green indicator)
Schedule Trigger shows next execution time
```

### Step 4.6: Test Automatic Execution

1. **Send another test email**
2. **Label it:** "Competitor Alerts"
3. **Mark as unread**
4. **Wait 1 minute** (schedule runs every minute)
5. Go to **Executions** (left sidebar in n8n)
6. **Expected:** New execution appears
7. Click execution to view details
8. **Verify:** Green (success), all nodes completed
9. **Check Drive:** New report file created
10. **Check Gmail:** Email marked as read

### 🚪 GATE 4: Final Verification

**Complete system check:**

```
Infrastructure:
- [ ] Docker containers running (docker ps)
- [ ] Both on same network (docker ps --format)
- [ ] Tunnel connected (docker logs cloudflared)
- [ ] n8n accessible via HTTPS

Credentials:
- [ ] Gmail OAuth2 working
- [ ] Google Drive OAuth2 working
- [ ] OpenAI API working

Workflow:
- [ ] CROWS NEST imported
- [ ] All nodes configured
- [ ] Manual test successful
- [ ] Automatic execution successful
- [ ] Reports generating in Drive
- [ ] Emails being marked as read

Testing:
- [ ] Test email → labeled → processed → report created
- [ ] Execution history shows success
- [ ] No errors in logs
```

**If ALL checks pass: YOU'RE DONE. System is fully operational.**

---

## 🚨 CRITICAL FAILURE POINTS (What Caused 3am Hell)

### Issue 1: Docker Network Alias Missing
**Symptom:** Error 502, "lookup n8n on 127.0.0.11:53: no such host"
**Cause:** n8n container had no DNS alias on the network
**Fix:** Ensure docker-compose.yml has `aliases: - n8n` under n8n service networks

### Issue 2: Multiple Tunnel Instances
**Symptom:** Accessing wrong n8n instance, old data showing
**Cause:** Same tunnel ID running on multiple machines
**Fix:** Use separate tunnel per environment/machine

### Issue 3: Wrong docker-compose.yml Edited
**Symptom:** Changes don't take effect
**Cause:** Editing n8n-local/docker-compose.yml but containers started from different file
**Fix:** Verify which compose file is actually running (`docker inspect [container]`)

### Issue 4: Tunnel config.yml Not Mounted
**Symptom:** "config file not found" in cloudflared logs
**Cause:** Volume mount incorrect or file missing
**Fix:** Verify `~/.cloudflared:/etc/cloudflared:ro` mount exists

### Issue 5: OAuth Redirect URI Mismatch
**Symptom:** "redirect_uri_mismatch" error during OAuth
**Cause:** Google Console URI doesn't match n8n callback URL
**Fix:** Must be exact: `https://n8n.improvemyrankings.com/rest/oauth2-credential/callback`

---

## 📞 Support / Debugging

**If you hit an issue:**

1. **Identify the layer** where it's failing
2. **Stop and fix that layer** before proceeding
3. **Re-run the gate verification** for that layer
4. **Do NOT skip to next layer** until current layer passes

**Common debugging commands:**

```bash
# Docker status
docker ps
docker ps --format "table {{.Names}}\t{{.Networks}}\t{{.Status}}"

# Logs
docker logs n8n --tail 50
docker logs cloudflared --tail 50

# Network check
docker inspect n8n -f '{{range $key, $value := .NetworkSettings.Networks}}{{$key}}: {{.Aliases}}{{end}}'

# DNS test
docker exec cloudflared nslookup n8n

# Public access test
curl -I https://n8n.improvemyrankings.com
```

---

## ✅ Success Criteria

**You know it's working when:**

1. ✅ `https://n8n.improvemyrankings.com` loads in browser
2. ✅ Can login with basic auth
3. ✅ All credentials show green/connected
4. ✅ CROWS NEST workflow is active
5. ✅ Test email → labeled → wait 1 min → report in Drive
6. ✅ Email marked as read
7. ✅ Executions tab shows green (success)
8. ✅ Docker containers stay running
9. ✅ Tunnel stays connected
10. ✅ No 502/1033 errors

---

## 🎯 Estimated Time by Layer

- **Layer 0:** 15 minutes (verification/installation)
- **Layer 1:** 20 minutes (Cloudflare tunnel setup)
- **Layer 2:** 30 minutes (Docker configuration)
- **Layer 3:** 40 minutes (Credentials + workflow import)
- **Layer 4:** 15 minutes (Testing)

**Total:** ~2 hours for first-time setup

**Subsequent setups (if this doc is followed):** ~45 minutes

---

**This guide eliminates the 3am nightmare. Follow it layer by layer. Do not skip gates. You will succeed.**
