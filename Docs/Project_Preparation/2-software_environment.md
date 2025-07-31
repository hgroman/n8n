# Software Environment for n8n Self-Hosting Project

## Core Development Tools (Mac)

### Container & Development Stack
- **Docker Desktop**: Version 4.42.1 (essential for n8n containerization)
- **Homebrew**: Package manager with essential formulas
- **Node.js**: Version 24.3.0 (for custom scripting if needed)
- **PostgreSQL**: Version 14.17_1 (for production database persistence)

### Homebrew Packages (Key Formulas)
- **postgresql@14**: Database for production persistence
- **node@24.3.0**: JavaScript runtime for custom scripts
- **ffmpeg@7.1.1**: Media processing (if needed for future workflows)
- **curl**: HTTP client for testing webhooks
- **tree**: Directory structure visualization

### Homebrew Casks
- **chromedriver**: Browser automation testing
- **gcloud-cli**: Google Cloud integration tools

## Current n8n Instance
- **n8n Cloud**: Active instance at `lastapple.app.n8n.cloud`
- **Status**: Configured with HubSpot and Gmail credentials
- **Migration Target**: Export workflows to self-hosted instance

## Integration Applications

### Productivity & AI Tools
- **Notion**: Documentation and knowledge management
- **Claude**: AI assistance and automation
- **Perplexity**: Research and information gathering
- **Google Workspace**: Gmail, Drive, Sheets integration

### Creative & Business Tools
- **Adobe Lightroom Classic**: Version 14.3.1
- **Logic Pro**: Version 11.2.1 (audio processing if needed)
- **Native Instruments Kontakt**: Version 6.8.0

### Email & Communication
- **Amazon SES**: Email delivery service
- **Beefree.io**: Email template creation
- **Gmail OAuth2**: Authentication for email workflows

## Tools to Install
- **ngrok**: Via Homebrew - for HTTPS tunneling during development
  ```bash
  brew install ngrok
  ```

## Software Compatibility
- **No Conflicts**: Current software stack supports n8n deployment
- **Resource Availability**: Sufficient system resources for Docker containers
- **Integration Ready**: OAuth and API credentials already configured

## Raw Inventory Reference
- Complete software inventory available in `mac_app_inventory_MacBook-Pro.local_20250713.json`
- Focus on Docker/Homebrew ecosystem for project setup

## References
- See `Hardware_Infrastructure.md` for device specifications
- See `HubSpot_Integration.md` for OAuth credential details
- See `Technical_Requirements.md` for environment variable configuration