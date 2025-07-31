# n8n Self-Hosted Workflow Automation Platform

A complete self-hosted n8n deployment with Docker, Cloudflare Tunnel, and Windows Server support.

## 🚀 Overview

This repository contains a production-ready n8n workflow automation setup with:

- **Docker Compose** configuration for easy deployment
- **Cloudflare Tunnel** for secure external access
- **Windows Server** deployment support
- **Automated backups** and monitoring
- **Pre-built workflows** for HubSpot, AWS SES, and Google integrations

## 📁 Repository Structure

```
├── Docs/                          # Project documentation
│   ├── Project_Preparation/       # Initial planning and research
│   └── Project_Implementation/    # Step-by-step implementation guides
├── n8n-local/                    # Local development setup
│   ├── docker-compose.yml        # Development Docker configuration
│   └── backup.sh                 # macOS/Linux backup script
├── n8n-Workflows/                # Workflow definitions
│   ├── HubSpot to AWS SES.json   # HubSpot integration workflow
│   ├── Life Architect.json       # Personal productivity workflow
│   └── [other workflows]         # Additional automation workflows
├── windows-deployment/           # Windows Server deployment files
│   ├── docker-compose.yml       # Windows-compatible Docker config
│   ├── deploy.ps1               # Automated deployment script
│   ├── backup.ps1               # Windows backup script
│   ├── install-service.ps1      # Windows service installer
│   ├── .env.example             # Environment configuration template
│   ├── README.md                # Windows deployment guide
│   └── MIGRATION_CHECKLIST.md   # Complete migration checklist
├── process_inventory.py          # Mac application inventory utility
└── README.md                     # This file
```

## 🛠️ Quick Start

### For Local Development (macOS/Linux)

1. **Clone the repository:**
   ```bash
   git clone https://github.com/hgroman/n8n.git
   cd n8n
   ```

2. **Start local development:**
   ```bash
   cd n8n-local
   docker-compose up -d
   ```

3. **Access n8n:**
   - Local: http://localhost:5678
   - Public: https://n8n.improvemyrankings.com

### For Windows Server Production

1. **Clone the repository:**
   ```powershell
   git clone https://github.com/hgroman/n8n.git
   Set-Location n8n\windows-deployment
   ```

2. **Follow the deployment guide:**
   ```powershell
   # See windows-deployment/README.md for complete instructions
   .\deploy.ps1
   ```

## 🔧 Configuration

### Environment Variables

Key configuration options (see `.env.example`):

| Variable | Description | Default |
|----------|-------------|---------|
| `N8N_BASIC_AUTH_USER` | Admin username | `admin` |
| `N8N_BASIC_AUTH_PASSWORD` | Admin password | `changeme` |
| `N8N_DOMAIN` | Your domain | `n8n.improvemyrankings.com` |
| `DB_TYPE` | Database type | `sqlite` |

### Integrations

This setup includes pre-configured workflows for:

- **HubSpot**: Contact management and automation
- **AWS SES**: Email sending and bounce handling
- **Google Services**: OAuth integration for various Google APIs

## 📊 Workflows

### Available Workflows

1. **HubSpot to AWS SES** - Email automation with bounce handling
2. **Life Architect** - Personal productivity and task management
3. **Competitor Monitoring** - Automated competitive intelligence
4. **Strategic Outreach Monitor** - HubSpot contact monitoring

### Importing Workflows

1. Access your n8n instance
2. Go to **Workflows** → **Import from File**
3. Select workflow JSON files from `n8n-Workflows/` directory
4. Configure credentials for each integration

## 🔐 Security

### Authentication

- Basic authentication enabled by default
- HTTPS enforced via Cloudflare
- Secure cookie settings for production

### Credentials Management

- AWS SES: IAM user with SES permissions (us-west-2 region)
- HubSpot: Developer API credentials
- Google OAuth: OAuth 2.0 client credentials

### Network Security

- Cloudflare Tunnel for secure external access
- No direct port exposure to internet
- Internal Docker network isolation

## 🔄 Backup & Recovery

### Automated Backups

- **macOS/Linux**: `n8n-local/backup.sh`
- **Windows**: `windows-deployment/backup.ps1`
- **Retention**: 7 days by default
- **Format**: SQLite database snapshots

### Manual Backup

```bash
# macOS/Linux
./backup.sh

# Windows
.\backup.ps1
```

## 📈 Monitoring

### Health Checks

- Docker container health monitoring
- Cloudflare tunnel status
- Workflow execution monitoring

### Logs

- Docker Compose logs: `docker-compose logs -f`
- n8n application logs: Available through web interface
- System logs: Windows Event Log (if using service)

## 🚀 Deployment Options

### Development (Local)

- Quick setup with `docker-compose up`
- SQLite database for simplicity
- Local file system for data persistence

### Production (Windows Server)

- Windows Service integration
- Automated deployment scripts
- Production-grade configuration
- Comprehensive monitoring and backup

## 🛠️ Maintenance

### Updates

```bash
# Pull latest images
docker-compose pull

# Restart with new images
docker-compose up -d
```

### Database Maintenance

- Regular backups via automated scripts
- SQLite database optimization
- Workflow export for version control

## 📚 Documentation

Comprehensive documentation available in the `Docs/` directory:

- **Project Preparation**: Initial planning and requirements
- **Project Implementation**: Step-by-step setup guides
- **Windows Deployment**: Complete Windows Server guide
- **Migration Checklist**: Detailed migration procedures

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For issues and questions:

1. Check the documentation in `Docs/`
2. Review the troubleshooting sections
3. Check existing GitHub issues
4. Create a new issue with detailed information

## 🏗️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Cloudflare    │    │   Docker Host    │    │   External      │
│     Tunnel      │────│                  │────│  Integrations   │
│                 │    │  ┌─────────────┐ │    │                 │
└─────────────────┘    │  │     n8n     │ │    │  • HubSpot      │
                       │  │  Container  │ │    │  • AWS SES      │
                       │  └─────────────┘ │    │  • Google APIs  │
                       │                  │    │                 │
                       │  ┌─────────────┐ │    └─────────────────┘
                       │  │  SQLite DB  │ │
                       │  │   Volume    │ │
                       │  └─────────────┘ │
                       └──────────────────┘
```

---

**Built with ❤️ for workflow automation**

*Last updated: July 30, 2025*
