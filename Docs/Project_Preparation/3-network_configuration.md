# Network Configuration for n8n Self-Hosting Project

## Domain and DNS Management

### Primary Domain
- **Domain**: `lastapple.com`
- **Registrar/Provider**: SiteGround (existing account)
- **DNS Zone Editor**: SiteGround management panel
- **Subdomain for n8n**: `n8n.lastapple.com`

### Existing DNS Records
- **MX Records**: Email routing configured
- **TXT Records**: SPF/DKIM for email authentication
- **A Records**: Current website hosting

### n8n Subdomain Setup
- **Target Record**: A record pointing to production server IP
- **Alternative**: CNAME for proxy/tunnel services
- **SSL**: Let's Encrypt via Traefik automation

## Network Architecture

### Secure Internal Access
- **VPN Solution**: Tailscale mesh network
- **Version**: 1.84.x installed on all devices
- **Coverage**: Mac, Tower, Laptop, iPhone
- **Purpose**: Secure cross-device management and administration

### Public Exposure Strategy

#### Development/Testing
- **Tool**: ngrok for temporary HTTPS tunnels
- **Use Case**: OAuth callback testing, webhook development
- **Benefits**: Avoids port forwarding, provides HTTPS
- **Inspection**: Available at `http://localhost:4040`

#### Production Options
1. **Preferred**: Cloudflare Tunnel or similar proxy service
2. **Alternative**: Dynamic DNS (No-IP, DuckDNS) if needed
3. **Fallback**: Return to hosted n8n if exposure risks too high

### Security Considerations
- **ISP IP**: Likely dynamic (no static IP confirmed)
- **Port Forwarding**: Avoided due to security risks
- **SSL**: Mandatory HTTPS-only access
- **Authentication**: Basic auth for production instance

## Network Flow Architecture

### Development Flow
```
Internet → ngrok tunnel → Mac (localhost:5678) → n8n instance
```

### Production Flow
```
Internet → n8n.lastapple.com → Traefik (SSL) → Docker container → n8n
```

### Management Flow
```
Admin device → Tailscale → Production server → Docker management
```

## Firewall and Access Control
- **Default**: Standard router/ISP firewall
- **Additional**: No custom VPN blocks beyond Tailscale
- **Monitoring**: Container logs for security events

## DNS Preparation Checklist
- [ ] Add A record for `n8n.lastapple.com`
- [ ] Configure Traefik for automatic SSL
- [ ] Test DNS propagation
- [ ] Update OAuth redirect URIs

## References
- See `Hardware_Infrastructure.md` for Tailscale IP addresses
- See `HubSpot_Integration.md` for OAuth callback URL requirements
- See `Technical_Requirements.md` for Traefik SSL configuration