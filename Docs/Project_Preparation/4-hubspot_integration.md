# HubSpot Integration for n8n Project

## Historical Issues and Resolutions

### Past Roadblocks
- **Localhost Issues**: 
  - Errors: "Invalid redirect URI" and connection timeouts
  - Root Cause: HubSpot requires public HTTPS endpoints
  - Problem: `localhost:5678` unreachable from HubSpot servers
  - Solution: Use ngrok for development, proper domain for production

- **Legacy Developer Account**:
  - Error: "Insufficient scopes" 
  - Root Cause: Sandbox/legacy account limitations
  - Solution: Created new developer account with full permissions

## Current HubSpot Developer App

### Application Details
- **Client ID**: `ca2a9792-3580-4607-a0f4-2a94690d3992`
- **App ID**: `15976984`
- **Status**: Active with full scope permissions
- **Plan**: Free HubSpot plan (with limitations noted below)

### OAuth Configuration
- **Current Redirect URI**: `https://oauth.n8n.cloud/oauth2/callback`
- **Testing URI**: Will use ngrok URL (e.g., `https://abc123.ngrok.io/rest/oauth2-credential/callback`)
- **Production URI**: `https://n8n.lastapple.com/rest/oauth2-credential/callback`

### Enabled Scopes
Complete scope list for comprehensive CRM access:
- `oauth`
- `forms`
- `tickets`
- `crm.objects.companies.read`
- `crm.objects.companies.write`
- `crm.schemas.companies.read`
- `crm.schemas.contacts.read`
- `crm.objects.contacts.read`
- `crm.objects.contacts.write`
- `crm.objects.deals.read`
- `crm.objects.deals.write`
- `crm.schemas.deals.read`
- `crm.objects.owners.read`
- `crm.lists.write`

## Custom Properties Configuration

### Strategic Outreach Field
- **Field Name**: "Strategic Outreach"
- **Type**: Dropdown/Select
- **Options**:
  - AI Consulting = Yes
  - Reconnect = No
  - AI Newsletter Signup = AI Newsletter Signup
  - WordPress Support = WordPress Support
  - SEO = SEO
  - Marketing General = Marketing General

### Plan Limitations
- **Free Plan Constraint**: Cannot modify existing custom field options
- **Workaround**: Accept current field structure and work with existing values
- **Impact**: Minor - workflow can handle all current dropdown values

## Working Workflow Details

### Current Cloud Implementation
- **Trigger**: HubSpot Property Change
- **Property**: "Strategic Outreach" (not "email_is_bad" as shown in JSON)
- **Action**: Gmail send message
- **Recipients**: `hank@lastapple.com`
- **Subject**: "Strategic Outreach Field Changed"
- **Body**: Static message (to be enhanced with dynamic content)

### Planned Enhancements
- **Dynamic Content**: Include contact's first name and company
- **Conditional Logic**: Branch by dropdown value using IF nodes
- **Email Templates**: Integration with Beefree.io via Amazon SES
- **Data Population**: Use expressions like `{{ $json["object"]["properties"]["firstname"] }}`

## Testing Protocol

### Sample Test Scenario
1. Access HubSpot contact record
2. Change "Strategic Outreach" value (e.g., "Reconnect" → "AI Consulting")
3. Verify n8n workflow triggers
4. Confirm email delivery with correct dynamic content

### Workflow Export
- **JSON File**: `HubSpot - Strategic Outreach Monitor.json`
- **Import Process**: Direct import into self-hosted n8n
- **Required Updates**: OAuth credentials and webhook URLs

## Migration Checklist
- [ ] Export workflow JSON from cloud instance
- [ ] Update redirect URIs in HubSpot app settings
- [ ] Re-authenticate OAuth in self-hosted instance
- [ ] Test webhook endpoint accessibility
- [ ] Verify property change triggers work correctly

## References
- See `Network_Configuration.md` for webhook URL and SSL setup
- See `Workflow_Definitions.md` for enhanced automation plans
- See `Technical_Requirements.md` for environment variable configuration