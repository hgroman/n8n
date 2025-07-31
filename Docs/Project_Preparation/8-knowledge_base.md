# Knowledge Base for n8n Self-Hosting Project

## Lessons Learned from Previous Conversations

### Key Insights from Grok Discussions

#### Project Philosophy
- **Cost-Benefit Focus**: Self-hosting saves $500+ annually vs cloud subscription
- **Simplicity Priority**: Start simple, add complexity gradually
- **Infrastructure First**: DNS and network preparation prevents rework
- **Migration Strategy**: Mac testing → Windows production deployment

#### Technical Recommendations
- **CLI Efficiency**: Create aliases like `n8n-up='docker compose up -d'` for deployment
- **Data Persistence**: Always use Docker volumes for configuration and data
- **SSL Automation**: Traefik preferred over manual certificate management
- **Backup Strategy**: Regular exports more important than complex backup systems

### Insights from Perplexity Research

#### OAuth and Authentication Solutions
- **HubSpot Issues**: New developer account resolved scope limitations
- **URI Matching**: Exact callback URL matching critical for OAuth success
- **Development URLs**: ngrok provides reliable HTTPS for OAuth testing

#### Environment Configuration
```bash
# Critical environment variables identified
N8N_WEBHOOK_TUNNEL_URL=https://ngrok-url    # For development
WEBHOOK_URL=https://n8n.lastapple.com       # For production
N8N_PROTOCOL=https                          # Force HTTPS
N8N_DEFAULT_WEBHOOK_TIMEOUT=120000          # Extend timeout
```

#### Docker Compose Best Practices
- **Restart Policy**: `restart: unless-stopped` for production reliability
- **Volume Structure**: `/home/node/.n8n` for persistent data
- **Port Management**: 5678 for development, 443 for production
- **Health Checks**: Built-in Docker health monitoring

#### Migration Strategy
- **Export First**: Always export workflows before infrastructure changes
- **Credential Recreation**: Don't migrate credentials, recreate for security
- **URI Updates**: Update all OAuth redirect URIs during migration
- **Testing Protocol**: Use ngrok