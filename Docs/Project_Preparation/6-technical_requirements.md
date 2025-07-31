# Technical Requirements for n8n Self-Hosting Project

## Docker Architecture

### Container Stack
- **n8n**: Latest stable image (`n8nio/n8n:latest`)
- **PostgreSQL**: Version 14+ for production database
- **Traefik**: Reverse proxy with automatic SSL
- **Optional**: Redis for queue mode (if scaling needed)

### Docker Compose Configuration

#### Essential Environment Variables
```yaml
environment:
  # Core n8n Configuration
  - N8N_PROTOCOL=https
  - N8N_PORT=443
  - N8N_EDITOR_BASE_URL=https://n8n.lastapple.com
  - WEBHOOK_URL=https://n8n.lastapple.com
  
  # Development/Testing
  - N8N_WEBHOOK_TUNNEL_URL=https://abc123.ngrok.io  # For ngrok testing
  
  # Security
  - N8N_SECURE_COOKIE=true
  - N8N_BASIC_AUTH_ACTIVE=true
  - N8N_BASIC_AUTH_USER=admin
  - N8N_BASIC_AUTH_PASSWORD=secure_password_here
  
  # Performance
  - N8N_DEFAULT_WEBHOOK_TIMEOUT=120000
  - N8N_TIMEOUT_THRESHOLD=300
  
  # Database (Production)
  - DB_TYPE=postgresdb
  - DB_POSTGRESDB_HOST=postgres
  - DB_POSTGRESDB_PORT=5432
  - DB_POSTGRESDB_DATABASE=n8n
  - DB_POSTGRESDB_USER=n8n
  - DB_POSTGRESDB_PASSWORD=secure_db_password
```

#### Volume Configuration
```yaml
volumes:
  - n8n_data:/home/node/.n8n
  - ./backups:/backups
```

#### Container Settings
```yaml
restart: unless-stopped
ports:
  - "5678:5678"  # Development
  - "443:443"    # Production with Traefik
```

## SSL and Reverse Proxy

### Traefik Configuration
- **Automatic SSL**: Let's Encrypt certificates
- **Domain**: `n8n.lastapple.com`
- **Renewal**: Automatic certificate renewal
- **Redirect**: HTTP to HTTPS enforcement

### Development SSL
- **ngrok**: Provides HTTPS tunneling for OAuth testing
- **Local Access**: `http://localhost:5678` for development
- **Tunnel Access**: `https://random.ngrok.io` for external services

## Database Requirements

### Development Database
- **Type**: SQLite (embedded)
- **Location**: `/home/node/.n8n/database.sqlite`
- **Backup**: File-based copy
- **Performance**: Adequate for testing and low-volume development

### Production Database
- **Type**: PostgreSQL 14+
- **Configuration**: Docker container with persistent volumes
- **Connection**: Internal Docker network
- **Backup**: pg_dump automated daily
- **Performance**: Optimized for concurrent workflow execution

## Security Configuration

### Authentication
- **Basic Auth**: Username/password for web UI access
- **OAuth**: Service-specific authentication (HubSpot, Gmail, etc.)
- **API Keys**: Secure storage for external service credentials

### Network Security
- **HTTPS Only**: All external communication encrypted
- **Internal Network**: Docker container networking
- **Firewall**: Standard router/ISP protection
- **VPN Access**: Tailscale for administrative access

### Data Protection
- **Credential Encryption**: n8n built-in credential encryption
- **Backup Encryption**: Encrypted backup storage
- **Log Security**: Sensitive data filtering in logs

## Performance Specifications

### Resource Allocation
- **CPU**: 2-4 cores recommended
- **RAM**: 4-8 GB for production workload
- **Storage**: 50+ GB for data, logs, and backups
- **Network**: Standard broadband (upload critical for webhooks)

### Scaling Considerations
- **Queue Mode**: Available if execution volume increases
- **Load Balancing**: Not required for current workload
- **Caching**: Redis integration if performance optimization needed

## Integration Requirements

### API Rate Limits
- **HubSpot**: Standard free tier limits
- **Gmail**: Google API quotas
- **Amazon SES**: Sending limits per region
- **AI Services**: Token-based usage limits

### Webhook Configuration
- **Public Endpoint**: Required for HubSpot webhooks
- **SSL Certificate**: Must be valid and trusted
- **Response Time**: < 30 seconds for webhook acknowledgment
- **Error Handling**: Proper HTTP status codes

## Monitoring and Logging

### Application Monitoring
- **Execution Logs**: Built-in n8n logging
- **Error Tracking**: Email notifications for failures
- **Performance Metrics**: Execution time and success rates

### Infrastructure Monitoring
- **Container Health**: Docker health checks
- **Database Performance**: Connection and query monitoring
- **SSL Certificate**: Expiration tracking
- **Disk Space**: Storage usage alerts

## Backup and Recovery

### Backup Strategy
- **Frequency**: Daily automated backups
- **Components**: Workflows, credentials, execution data
- **Storage**: Local and cloud backup copies
- **Testing**: Regular backup restoration testing

### Recovery Procedures
- **Workflow Export**: JSON-based configuration backup
- **Database Restore**: Point-in-time recovery capability
- **Credential Migration**: Secure credential transfer process
- **Rollback Plan**: Previous version restoration capability

## Development Tools

### Local Development
- **Docker Desktop**: Container development environment
- **ngrok**: HTTPS tunneling for webhook testing
- **Postman**: API testing and webhook simulation
- **Git**: Version control for configurations

### Deployment Tools
- **Docker Compose**: Container orchestration
- **CLI Aliases**: Simplified deployment commands
- **Backup Scripts**: Automated backup and restore procedures
- **Monitoring Scripts**: Health check and alerting automation

## References
- See `Network_Configuration.md` for DNS and SSL setup details
- See `Hardware_Infrastructure.md` for system specifications
- See `Implementation_Plan.md` for deployment timeline and procedures