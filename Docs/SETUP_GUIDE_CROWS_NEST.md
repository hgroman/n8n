# Setup Guide: n8n CROWS NEST Competitor Intelligence Workflow

**Last Updated:** 2025-11-25
**Workflow File:** `n8n_CROWS_NEST_07.23.25-3.json`
**Status:** Production-Ready

---

## Overview

The CROWS NEST workflow is an AI-powered competitor intelligence system that:
- Monitors Gmail for competitor emails (using labels)
- Extracts and parses email content
- Performs sophisticated AI analysis using OpenAI O4-mini
- Creates detailed markdown reports in Google Drive
- Automatically marks processed emails as read

**Execution Frequency:** Every 1 minute
**Average Processing Time:** 10-30 seconds per email

---

## Prerequisites

Before importing the workflow, ensure you have:

- ✅ Fresh n8n installation (Docker-based recommended)
- ✅ Access to Google Cloud Console
- ✅ OpenAI account with API access
- ✅ Gmail account to monitor
- ✅ Google Drive for report storage

---

## Part 1: Google Cloud Platform Setup

### Step 1: Enable Required APIs

1. Go to [Google Cloud Console](https://console.cloud.google.com)
2. Select your project (or create new: "n8n-automation")
3. Navigate to **APIs & Services** → **Library**
4. Enable these APIs:
   - **Gmail API**
   - **Google Drive API**

### Step 2: Configure OAuth Consent Screen

1. Go to **APIs & Services** → **OAuth consent screen**
2. Choose **External** user type
3. Fill in application information:
   - **App name:** n8n Automation
   - **User support email:** Your email
   - **Developer contact:** Your email
4. Add these scopes:
   - `https://www.googleapis.com/auth/gmail.modify`
   - `https://www.googleapis.com/auth/gmail.send`
   - `https://www.googleapis.com/auth/drive`
   - `https://www.googleapis.com/auth/drive.file`
5. Add test users: Your Gmail address
6. Save and continue

### Step 3: Create OAuth2 Credentials

1. Go to **APIs & Services** → **Credentials**
2. Click **Create Credentials** → **OAuth 2.0 Client ID**
3. Application type: **Web application**
4. Name: "n8n Integration"
5. **Authorized redirect URIs:** Add your n8n callback URL:
   ```
   https://n8n.improvemyrankings.com/rest/oauth2-credential/callback
   ```
   OR if running locally:
   ```
   http://localhost:5678/rest/oauth2-credential/callback
   ```
6. Click **Create**
7. **IMPORTANT:** Copy the **Client ID** and **Client Secret** immediately

---

## Part 2: Gmail Label Setup

### Create Competitor Intelligence Label

1. Open Gmail
2. Click the **Settings gear** → **See all settings**
3. Go to **Labels** tab
4. Click **Create new label**
5. Name it: **"Competitor Alerts"**
6. Optional: Create a filter to auto-label competitor emails:
   - Settings → **Filters and Blocked Addresses**
   - **Create a new filter**
   - Example criteria:
     - From: Contains competitor domains
     - Subject: Contains specific keywords
   - Apply label: "Competitor Alerts"

### Get Label ID (Important!)

The workflow uses label ID, not name. Two ways to get it:

**Option A: From n8n (Easiest)**
1. In n8n, create a Gmail node
2. Operation: "Get Many Messages"
3. In "Filters" → "Label IDs", click the dropdown
4. You'll see all labels with their IDs

**Option B: Via Gmail API**
```bash
# You'll need to authenticate, but this shows the format
curl -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  https://gmail.googleapis.com/gmail/v1/users/me/labels
```

**Current workflow uses:** `Label_1688379935863361814`
You'll need to update this with your label ID.

---

## Part 3: Google Drive Folder Setup

### Create Report Storage Folder

1. Go to [Google Drive](https://drive.google.com)
2. Click **New** → **Folder**
3. Name it: **"Crows Nest"** (or your preferred name)
4. Right-click the folder → **Get link** → **Copy link**
5. Extract the folder ID from the URL:
   ```
   https://drive.google.com/drive/folders/1HP7Pii6-MrUr5R4Y3GGkIk84ReV6QQIc
                                            ↑
                                    This is your folder ID
   ```

**Current workflow uses:** `1HP7Pii6-MrUr5R4Y3GGkIk84ReV6QQIc`
You'll need to update this with your folder ID.

---

## Part 4: OpenAI API Setup

### Get API Key

1. Go to [OpenAI Platform](https://platform.openai.com)
2. Sign in or create account
3. Navigate to **API Keys** (left sidebar)
4. Click **Create new secret key**
5. Name it: "n8n-crows-nest"
6. **IMPORTANT:** Copy the key immediately (you won't see it again)

### Check Model Access

- The workflow uses: **O4-mini-2025-04-16**
- Verify you have access to this model in your account
- Alternative: You can modify the workflow to use `gpt-4o-mini` or `gpt-4-turbo`

---

## Part 5: Import and Configure Workflow

### Import the Workflow

1. Open your n8n instance
2. Click **Workflows** (left sidebar)
3. Click **Import from File**
4. Select: `n8n-Workflows/n8n_CROWS_NEST_07.23.25-3.json`
5. Click **Import**

### Configure Credentials

You'll need to reconnect all credentials after import:

#### 1. Gmail OAuth2 Credential

1. In the workflow, click any Gmail node
2. Click the **Credential** dropdown → **Create New**
3. Name: "Gmail account"
4. **Grant Type:** Authorization Code
5. **Authentication:** OAuth2
6. Paste your **Client ID** and **Client Secret** from Part 1
7. Click **Sign in with Google**
8. Authorize access
9. Click **Save**

#### 2. Google Drive OAuth2 Credential

1. Click the "Competitor Intel File Creator" node
2. Click **Credential** dropdown → **Create New**
3. Name: "n8n Google Drive"
4. Use the **same Client ID and Client Secret** as Gmail
5. Click **Sign in with Google**
6. Authorize access
7. Click **Save**

#### 3. OpenAI API Credential

1. Click the "AI Competitor Intelligence Analyzer" node
2. Click **Credential** dropdown → **Create New**
3. Name: "OpenAi account"
4. Paste your **API Key** from Part 4
5. Click **Save**

### Update Node Configuration

#### Update Gmail Label ID

1. Open the **"Get many messages"** node (node #7)
2. In **Filters** section
3. Find **Label IDs:** Currently shows `Label_1688379935863361814`
4. Click the dropdown and select your "Competitor Alerts" label
5. OR manually paste your label ID

#### Update Google Drive Folder ID

1. Open the **"Competitor Intel File Creator"** node (node #4)
2. In **Folder ID** field
3. Click the dropdown (it will refresh to show your folders)
4. Select your "Crows Nest" folder
5. OR manually paste your folder ID: `1HP7Pii6-MrUr5R4Y3GGkIk84ReV6QQIc`

#### Verify AI Model Selection

1. Open the **"AI Competitor Intelligence Analyzer"** node (node #2)
2. Check **Model ID:** Should show `O4-mini-2025-04-16`
3. If you don't have access, change to:
   - `gpt-4o-mini` (recommended, cost-effective)
   - `gpt-4-turbo` (more powerful, higher cost)

---

## Part 6: Testing the Workflow

### Pre-Flight Checks

Before activating, verify:
- [ ] All credential indicators are green (not red)
- [ ] Gmail label exists and has correct ID
- [ ] Google Drive folder exists and has correct ID
- [ ] OpenAI API key is valid

### Test Execution

1. **Send a test email:**
   - Send yourself an email from a competitor (or forward one)
   - Manually apply the "Competitor Alerts" label
   - Mark it as **unread**

2. **Manual test run:**
   - Click the **"Schedule Trigger"** node
   - Click **"Test step"** (don't click "Test workflow" yet)
   - This simulates the trigger

3. **Test each node sequentially:**
   - Click **"Get many messages"** → **"Test step"**
   - Verify it found your labeled email
   - Continue through each node
   - Check the output data at each step

4. **End-to-end test:**
   - Click **"Execute Workflow"** (top right)
   - Watch it process through all nodes
   - Check Google Drive for the generated report
   - Verify email is marked as read

### Expected Output

You should see a markdown file in Google Drive with:
- YAML frontmatter (metadata)
- Email details section
- AI competitive analysis (structured insights)
- Original email content
- Processing metadata

---

## Part 7: Activate the Workflow

### Activation

1. Toggle the workflow **Active** switch (top right)
2. The "Schedule Trigger" will now check every 1 minute
3. Monitor the **Executions** tab for activity

### Monitoring

- Go to **Executions** (left sidebar)
- Watch for new runs every minute
- Green = success, Red = error
- Click any execution to see detailed logs

---

## Troubleshooting

### Common Issues

#### "Could not retrieve data from Email Parser"
- **Cause:** Gmail node returned no results
- **Fix:** Ensure there's an unread email with the correct label

#### "AI returned unexpected format"
- **Cause:** OpenAI API error or model not available
- **Fix:** Check API key, verify billing, try different model

#### "Illegal address" or similar
- **Cause:** Data extraction issue in parser
- **Fix:** Check the "Email Parser & Domain Extractor" node output

#### "Folder not found"
- **Cause:** Wrong folder ID or insufficient permissions
- **Fix:** Verify folder ID, check Google Drive credential has proper scopes

#### Workflow runs but creates no files
- **Cause:** Usually credential or folder permission issue
- **Fix:** Re-authenticate Google Drive credential

### Debug Mode

1. Click any node
2. In the node panel, enable **"Always Output Data"**
3. This helps track data flow through the workflow

### Check Credentials

1. Go to **Credentials** (left sidebar)
2. Find each credential used in the workflow
3. Click **Test** to verify it's still valid
4. Re-authenticate if needed

---

## Maintenance

### Regular Tasks

- **Weekly:** Review generated reports in Google Drive
- **Monthly:** Check OpenAI API usage and costs
- **As needed:** Update AI prompt for better analysis

### Updating the AI Prompt

The AI prompt is in the **"AI Competitor Intelligence Analyzer"** node:

1. Open the node
2. Find the **Messages** section
3. Edit the content (very detailed prompt with YAML structure)
4. Key sections you can customize:
   - Analysis focus areas
   - Output format
   - Confidence ratings
   - Your company offerings (LastApple services)

### Cost Management

**Estimated costs per execution:**
- OpenAI O4-mini: ~$0.01-0.05 per email
- Gmail API: Free (generous quota)
- Google Drive API: Free (generous quota)

**Monthly estimate (if 10 emails/day):**
- 10 emails × 30 days = 300 emails/month
- 300 × $0.03 avg = ~$9/month OpenAI costs

---

## Security Best Practices

1. **Credential Security:**
   - Never share your n8n instance credentials
   - Use strong passwords for basic auth
   - Enable HTTPS (already done via Cloudflare)

2. **API Key Rotation:**
   - Rotate OpenAI API keys quarterly
   - Rotate Google OAuth credentials annually

3. **Access Control:**
   - Keep Google OAuth in "Test mode" if only you use it
   - Or complete OAuth app verification for production

4. **Data Privacy:**
   - Competitor emails may contain sensitive info
   - Secure your Google Drive folder (don't share publicly)
   - Consider n8n execution data retention settings

---

## Advanced Customization

### Change Polling Frequency

Current: Every 1 minute

To change:
1. Open **"Schedule Trigger"** node
2. Modify **Interval** settings
3. Options: Minutes, Hours, Days, Weeks, Cron expression

### Multiple Email Sources

To monitor multiple Gmail accounts:
1. Duplicate the workflow
2. Configure with different Gmail credentials
3. Use different labels or filters

### Alternative AI Providers

To use Anthropic Claude or other AI:
1. Replace the OpenAI node
2. Add Anthropic or other LangChain node
3. Adjust the prompt format accordingly

### Notification Add-on

Add Slack/Discord/Email notification on completion:
1. Add new node after "Mark a message as read"
2. Choose Slack, Discord, or Email node
3. Send summary notification with link to Drive file

---

## Support Resources

- **n8n Documentation:** https://docs.n8n.io
- **n8n Community:** https://community.n8n.io
- **OpenAI API Docs:** https://platform.openai.com/docs
- **Gmail API Docs:** https://developers.google.com/gmail/api
- **Google Drive API Docs:** https://developers.google.com/drive/api

---

## Workflow Node Reference

| Node Name | Type | Purpose |
|-----------|------|---------|
| Schedule Trigger | Schedule Trigger | Runs every 1 minute |
| Get many messages | Gmail | Fetches unread emails with label |
| Get a message | Gmail | Gets full email details |
| Email Parser & Domain Extractor | Code (JavaScript) | Extracts text, sender, domain |
| AI Competitor Intelligence Analyzer | OpenAI | Performs AI analysis |
| Data Merger & AI Integration | Code (JavaScript) | Merges parsed data with AI results |
| Competitor Intel File Creator | Google Drive | Creates markdown report |
| Mark a message as read | Gmail | Marks email as processed |

---

## Quick Reference Commands

### Check n8n is running
```bash
docker ps | grep n8n
```

### View n8n logs
```bash
docker logs -f n8n-local-n8n-1
```

### Restart n8n
```bash
cd ~/n8n/n8n-local
docker-compose restart
```

### Backup workflow
```bash
# Export from n8n UI: Settings → Export
# Or backup entire database
cp ~/.n8n/database.sqlite ~/.n8n/backups/database-$(date +%Y%m%d).sqlite
```

---

**You're now ready to run the CROWS NEST workflow!** 🎉

Start by sending a test competitor email to yourself, labeling it, and watching the magic happen.
