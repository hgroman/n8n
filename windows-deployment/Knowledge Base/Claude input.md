Looking through the documents for answers to the Work Order questions:

### **SECTION A: Docker and Container Architecture**

**1. Docker Compose Configuration Issues:**

**From Technical Requirements.md:**
- Environment variable configurations critical for n8n operation:
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

**From Technical Requirements.md:**
- Volume configuration:
  ```yaml
  volumes:
    - n8n_data:/home/node/.n8n
    - ./backups:/backups
  ```

**2. Container Networking Challenges:**

**From Technical Requirements.md:**
- Port mapping configurations:
  ```yaml
  ports:
    - "5678:5678"  # Development
    - "443:443"    # Production with Traefik
  ```

### **SECTION C: OAuth and Webhook Integration**

**7. OAuth Configuration Challenges:**

**From HubSpot Integration.md:**
- "Localhost Issues: Errors: 'Invalid redirect URI' and connection timeouts. Root Cause: HubSpot requires public HTTPS endpoints. Problem: `localhost:5678` unreachable from HubSpot servers. Solution: Use ngrok for development, proper domain for production"

**From HubSpot Integration.md:**
- "Current Redirect URI: `https://oauth.n8n.cloud/oauth2/callback`"
- "Testing URI: Will use ngrok URL (e.g., `https://abc123.ngrok.io/rest/oauth2-credential/callback`)"
- "Production URI: `https://n8n.lastapple.com/rest/oauth2-credential/callback`"

**8. Webhook Endpoint Configuration:**

**From Technical Requirements.md:**
- "Webhook Configuration:
  - Public Endpoint: Required for HubSpot webhooks
  - SSL Certificate: Must be valid and trusted
  - Response Time: < 30 seconds for webhook acknowledgment
  - Error Handling: Proper HTTP status codes"

### **SECTION D: Database and Data Persistence**

**10. Database Configuration Issues:**

**From Technical Requirements.md:**
- "Development Database:
  - Type: SQLite (embedded)
  - Location: `/home/node/.n8n/database.sqlite`
  - Backup: File-based copy
  - Performance: Adequate for testing and low-volume development"

**From Technical Requirements.md:**
- "Production Database:
  - Type: PostgreSQL 14+
  - Configuration: Docker container with persistent volumes
  - Connection: Internal Docker network
  - Backup: pg_dump automated daily"

### **SECTION E: Security and Authentication**

**12. Authentication Configuration:**

**From Technical Requirements.md:**
- "Authentication:
  - Basic Auth: Username/password for web UI access
  - OAuth: Service-specific authentication (HubSpot, Gmail, etc.)
  - API Keys: Secure storage for external service credentials"

**From Technical Requirements.md:**
- "Network Security:
  - HTTPS Only: All external communication encrypted
  - Internal Network: Docker container networking
  - Firewall: Standard router/ISP protection
  - VPN Access: Tailscale for administrative access"

### **SECTION F: Monitoring and Troubleshooting**

**15. Troubleshooting Procedures:**

**From GROK_Analysis_Email_Parsing_Fixes.md:**
- "Debug Protocol:
  1. Isolate: Execute single nodes.
  2. Inspect: Pin data; validate expressions.
  3. Log: Add console logs for structures.
  4. Modularize: Branch workflows for parallel tasks (e.g., mark read separately from AI)."

**From SOP: n8n Dynamic Competitor Intelligence Workflow v1.1:**
- "Pin Data Early: Right-click nodes → Pin Data to inspect actual structures before writing code"
- "Explicit References: Use $('Node Name').first().json.field over $json.field in chains to prevent data overwrites"

### **SECTION G: Performance and Optimization**

**16. Resource Configuration:**

**From Technical Requirements.md:**
- "Resource Allocation:
  - CPU: 2-4 cores recommended
  - RAM: 4-8 GB for production workload
  - Storage: 50+ GB for data, logs, and backups
  - Network: Standard broadband (upload critical for webhooks)"

**17. Workflow Optimization:**

**From Technical Requirements.md:**
- Performance environment variables:
  - "N8N_DEFAULT_WEBHOOK_TIMEOUT=120000"
  - "N8N_TIMEOUT_THRESHOLD=300"