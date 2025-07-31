# Workflow Definitions for n8n Project

## Primary Workflows

### 1. HubSpot Strategic Outreach Automation

#### Current Implementation
- **Trigger**: HubSpot Contact Property Change
- **Property**: "Strategic Outreach" dropdown
- **Action**: Gmail notification to `hank@lastapple.com`
- **Status**: Working in cloud, ready for migration

#### Enhanced Version (Planned)
```
HubSpot Trigger (Property Change) 
→ IF Node (Branch by dropdown value)
  ├── "AI Consulting" → SES Email (AI consulting template)
  ├── "WordPress Support" → SES Email (WordPress template)  
  ├── "SEO" → SES Email (SEO template)
  └── Default → SES Email (General template)
→ Set Node (Populate dynamic fields)
  ├── First Name: {{ $json["object"]["properties"]["firstname"] }}
  ├── Company: {{ $json["object"]["properties"]["company"] }}
  └── Email: {{ $json["object"]["properties"]["email"] }}
→ Amazon SES Node (Send personalized email)
```

#### Dynamic Content Examples
- **Subject**: "Thanks for your interest in {{field}}, {{firstName}}!"
- **Template Variables**: Beefree.io template IDs stored as environment variables
- **Personalization**: Company name, contact preferences, follow-up timing

### 2. Gmail Competitor Intelligence Monitor

#### Workflow Design
```
Gmail Trigger (New email with label "Competitor Alerts")
→ AI Analysis Node (OpenAI/Claude)
  ├── Extract: Pricing information
  ├── Extract: Product features  
  ├── Extract: Market positioning
  └── Generate: Strategic insights summary
→ Google Drive Node (Upload summary)
  ├── Target Folder: "n8n-output" (using folder ID)
  ├── Filename: "Competitor_Analysis_{{date}}.md"
  └── Content: Structured markdown report
→ Gmail Node (Update label to "Summarized")
→ Optional: Slack/Teams notification
```

#### AI Prompt Template
```
Analyze this competitor email for:
1. Pricing changes or promotions
2. New product/service announcements  
3. Market positioning strategies
4. Actionable insights for our business

Email content: {{$json.body}}
```

### 3. Additional Planned Workflows

#### Lead Follow-up Automation
- **Trigger**: HubSpot deal stage change
- **Logic**: Time-delayed follow-up sequences
- **Output**: Personalized email campaigns

#### Google Workspace Data Logging
- **Trigger**: Various business events
- **Action**: Log to Google Sheets for analysis
- **Integration**: Connect with Obsidian/NotebookLM

#### Content Performance Tracking
- **Trigger**: Website analytics webhook
- **Processing**: Performance metrics analysis
- **Output**: Weekly summary reports

## Workflow Specifications

### Performance Requirements
- **Execution Volume**: 10-50 executions per day maximum
- **Resource Intensity**: Low (short AI summaries, simple data operations)
- **Polling Frequency**: Gmail every 5 minutes, HubSpot real-time webhooks
- **Error Handling**: Basic retry logic, email notifications for failures

### Data Flow Patterns
- **Webhooks**: HubSpot (real-time property changes)
- **Polling**: Gmail (label-based monitoring)
- **API Calls**: Google Drive, Amazon SES, AI services
- **Data Storage**: Minimal - mostly pass-through processing

### Integration Requirements
- **OAuth2**: HubSpot, Gmail, Google Drive
- **API Keys**: Amazon SES, OpenAI/Claude, other AI services
- **Webhooks**: Public HTTPS endpoints for real-time triggers
- **Templates**: Beefree.io HTML email templates

## Database and Persistence

### Development Setup
- **Database**: SQLite for local testing and development
- **Data Retention**: Standard n8n execution history
- **Backup**: File-based exports of workflow configurations

### Production Setup  
- **Database**: PostgreSQL for reliability and performance
- **Persistence**: Docker volumes for data and configuration
- **Monitoring**: Execution logs and error tracking

## Testing Strategy

### Unit Testing
- Individual node configuration and data mapping
- OAuth authentication and API connectivity
- Email delivery and template rendering

### Integration Testing
- End-to-end workflow execution
- Error handling and retry mechanisms
- Performance under typical load conditions

### User Acceptance Testing
- Business stakeholder review of email content
- Verification of data accuracy and timing
- Confirmation of actionable insights quality

## References
- See `HubSpot_Integration.md` for trigger configuration details
- See `Technical_Requirements.md` for environment and infrastructure setup
- See `Implementation_Plan.md` for development and deployment timeline