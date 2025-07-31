# WORK ORDER: n8n Windows Production Deployment

**Project**: n8n Self-Hosted Workflow Automation Platform  
**Phase**: Production Deployment to Windows Server  
**Current State**: Development system operational on macOS  
**Target State**: Production system operational on Windows Server  
**Repository**: https://github.com/hgroman/n8n.git  
**Date Created**: July 30, 2025  

---

## 🎯 EXECUTIVE SUMMARY

This work order documents the deployment of our fully functional n8n workflow automation platform from the current macOS development environment to a Windows Server production environment. The development system is currently operational with Docker, Cloudflare Tunnel, and integrated workflows for HubSpot, AWS SES, and Google OAuth. The production deployment will replicate this architecture on Windows Server while maintaining all functionality, security, and external integrations.

---

## 📊 CURRENT STATE ANALYSIS

### ✅ **Operational Development Environment (macOS)**
- **Platform**: Docker Desktop on macOS
- **n8n Version**: 1.104.1
- **Database**: SQLite with persistent volumes
- **External Access**: Cloudflare Tunnel (n8n.improvemyrankings.com)
- **Authentication**: Basic Auth + HTTPS
- **Backup System**: Automated SQLite backups (7-day retention)

### ✅ **Active Integrations**
- **HubSpot**: Developer API with webhook triggers
- **AWS SES**: Email automation (us-west-2 region, IAM policy configured)
- **Google OAuth**: Service integrations with proper redirect URLs
- **Cloudflare**: Tunnel configuration with certificate management

### ✅ **Workflow Inventory**
1. **HubSpot to AWS SES** - Email automation with bounce handling
2. **Life Architect** - Personal productivity automation
3. **Competitor Monitoring** (4 variants) - Automated competitive intelligence
4. **Strategic Outreach Monitor** - HubSpot contact monitoring
5. **CROWS_NEST** - Advanced monitoring workflow

---

## 🎯 TARGET DEPLOYMENT ARCHITECTURE

### **Windows Server Production Environment**
- **Platform**: Windows Server 2019/2022 with Docker Desktop
- **Container Orchestration**: Docker Compose (same as development)
- **Service Integration**: Windows Service for auto-startup
- **External Access**: Cloudflare Tunnel (same domain, new tunnel instance)
- **Security**: Enhanced with Windows-specific hardening
- **Monitoring**: Windows Event Log integration + Docker health checks

### **Critical Requirement: Tunnel Architecture**
**CHALLENGE**: OAuth callbacks from Google and HubSpot require consistent, accessible URLs for webhook endpoints and redirect URIs. The production Windows system must maintain the same external accessibility as the current Mac development system.

**SOLUTION APPROACH**: 
- Cloudflare Tunnel configuration replication
- Docker internal networking preservation
- Webhook URL consistency maintenance
- SSL certificate management

---

## 🚀 DEPLOYMENT STRATEGY

### **Phase 1: Infrastructure Preparation**
1. **Windows Server Setup**
   - Docker Desktop installation and WSL2 configuration
   - PowerShell 7+ installation
   - Network and firewall configuration

2. **Repository Deployment**
   ```powershell
   git clone https://github.com/hgroman/n8n.git
   cd n8n\windows-deployment
   ```

3. **Environment Configuration**
   - Copy `.env.example` to `.env`
   - Configure production passwords and encryption keys
   - Update domain-specific settings

### **Phase 2: Tunnel and Network Configuration**
1. **Cloudflare Tunnel Setup**
   - Generate new tunnel certificate for Windows server
   - Configure `cloudflared/config.yml` with production tunnel ID
   - Test tunnel connectivity and SSL termination

2. **Docker Network Validation**
   - Verify internal container communication
   - Test webhook endpoint accessibility
   - Validate OAuth redirect URL functionality

### **Phase 3: Service Deployment**
1. **Container Deployment**
   ```powershell
   .\deploy.ps1
   ```

2. **Windows Service Installation**
   ```powershell
   .\install-service.ps1
   ```

3. **Health Check Validation**
   - Container status verification
   - External access testing
   - Integration endpoint testing

### **Phase 4: Data Migration and Testing**
1. **Workflow Import**
   - Import all 9 workflow JSON files
   - Configure credentials for each integration
   - Test workflow execution

2. **Integration Validation**
   - HubSpot webhook callback testing
   - Google OAuth flow validation
   - AWS SES email sending verification

3. **Production Readiness**
   - Backup system activation
   - Monitoring configuration
   - Performance baseline establishment

---

## 🔍 ARCHITECTURAL HURDLES ANALYSIS

### **Known Challenges Overcome in Mac Development**

The following section contains strategic questions designed to extract architectural knowledge from previous LLM interactions during the Mac deployment phase. These questions should be used to query Claude, Perplexity, Grok, and ChatGPT projects where n8n deployment work was performed.

---

## 📋 LLM KNOWLEDGE EXTRACTION QUESTIONNAIRE

### **SECTION A: Docker and Container Architecture**

**Query Context**: "During our n8n deployment project, we worked through various Docker configuration challenges."

1. **Docker Compose Configuration Issues**:
   - What specific Docker Compose configuration problems did we encounter when setting up n8n with persistent volumes?
   - How did we resolve volume mounting issues between the host system and n8n container?
   - What environment variable configurations were critical for proper n8n operation in Docker?

2. **Container Networking Challenges**:
   - What Docker networking issues did we face when connecting n8n to external services?
   - How did we configure internal Docker networks to allow proper communication between n8n and cloudflared containers?
   - What port mapping and exposure configurations were necessary for webhook functionality?

3. **Image and Version Management**:
   - What n8n image version compatibility issues did we encounter?
   - How did we handle Docker image updates and rollback procedures?
   - What specific n8n configuration flags or environment variables were essential for stable operation?

### **SECTION B: Cloudflare Tunnel Integration**

**Query Context**: "We implemented Cloudflare Tunnel for secure external access to our self-hosted n8n instance."

4. **Tunnel Configuration Challenges**:
   - What specific Cloudflare Tunnel configuration errors did we encounter during setup?
   - How did we resolve the "is a directory" error with the cloudflared configuration?
   - What was the correct volume mounting strategy for cloudflared certificates and config files?

5. **SSL and Domain Configuration**:
   - How did we configure SSL termination and HTTPS enforcement through Cloudflare?
   - What domain and subdomain configuration steps were necessary for proper routing?
   - How did we handle certificate management and renewal processes?

6. **Network Routing and Ingress**:
   - What ingress rules and routing configurations were required in the Cloudflare Tunnel config?
   - How did we ensure proper traffic routing from external requests to the internal n8n container?
   - What troubleshooting steps did we use to validate tunnel connectivity?

### **SECTION C: OAuth and Webhook Integration**

**Query Context**: "We configured OAuth integrations with Google services and webhook endpoints for HubSpot."

7. **OAuth Configuration Challenges**:
   - What specific Google OAuth setup issues did we encounter during credential configuration?
   - How did we properly configure redirect URIs for the self-hosted n8n instance?
   - What scope and permission configurations were necessary for Google service integrations?

8. **Webhook Endpoint Configuration**:
   - How did we configure n8n webhook URLs to work properly with external services like HubSpot?
   - What webhook URL format and routing configurations were required?
   - How did we troubleshoot webhook delivery and callback issues?

9. **External Service Integration**:
   - What authentication and API configuration challenges did we face with HubSpot integration?
   - How did we configure AWS SES credentials and regional settings for email workflows?
   - What specific n8n node configuration was required for each external service?

### **SECTION D: Database and Data Persistence**

**Query Context**: "We configured SQLite database persistence and backup strategies for n8n."

10. **Database Configuration Issues**:
    - What database connection and persistence issues did we encounter with SQLite in Docker?
    - How did we ensure proper data persistence across container restarts and updates?
    - What backup and recovery procedures did we implement for the n8n database?

11. **Data Migration Challenges**:
    - How did we handle workflow export and import processes during configuration changes?
    - What data integrity checks and validation procedures did we establish?
    - How did we manage credential storage and security in the database?

### **SECTION E: Security and Authentication**

**Query Context**: "We implemented security measures including basic authentication and secure cookie configuration."

12. **Authentication Configuration**:
    - What authentication and authorization challenges did we face during n8n setup?
    - How did we configure basic authentication and secure cookie settings?
    - What security hardening steps did we implement for the self-hosted instance?

13. **Credential Management**:
    - How did we securely manage and store API credentials for external services?
    - What encryption and security measures did we implement for sensitive configuration data?
    - How did we handle credential rotation and updates in the production environment?

### **SECTION F: Monitoring and Troubleshooting**

**Query Context**: "We established monitoring, logging, and troubleshooting procedures for the n8n deployment."

14. **Logging and Monitoring Setup**:
    - What logging configuration and monitoring solutions did we implement?
    - How did we configure log rotation and retention policies?
    - What health check and alerting mechanisms did we establish?

15. **Troubleshooting Procedures**:
    - What common troubleshooting steps and diagnostic procedures did we develop?
    - How did we handle container restart and recovery scenarios?
    - What debugging techniques did we use for workflow execution issues?

### **SECTION G: Performance and Optimization**

**Query Context**: "We optimized the n8n deployment for performance and resource utilization."

16. **Resource Configuration**:
    - What memory and CPU resource limits did we configure for optimal performance?
    - How did we handle resource scaling and capacity planning?
    - What performance tuning parameters did we adjust in n8n configuration?

17. **Workflow Optimization**:
    - What workflow design patterns and optimization techniques did we implement?
    - How did we handle large data processing and batch operations?
    - What timeout and retry configurations did we establish for external service calls?

---

## 🎯 WINDOWS-SPECIFIC CONSIDERATIONS

### **Platform Translation Requirements**

1. **PowerShell vs Bash Scripts**:
   - All automation scripts converted from bash to PowerShell
   - Windows Service integration for automatic startup
   - Windows Event Log integration for monitoring

2. **File System and Permissions**:
   - Windows path format adaptation (C:\ vs /)
   - NTFS permission configuration for Docker volumes
   - Windows Defender exclusion configuration

3. **Network and Firewall**:
   - Windows Firewall rule configuration
   - Port access and security group management
   - Network adapter and routing considerations

### **Docker Desktop Windows Considerations**

1. **WSL2 Backend Requirements**:
   - WSL2 installation and configuration
   - Linux container compatibility
   - Resource allocation and performance tuning

2. **Volume Mounting Differences**:
   - Windows path format in Docker Compose
   - File permission mapping between Windows and Linux containers
   - Performance optimization for cross-platform volume access

---

## 📈 SUCCESS CRITERIA

### **Functional Requirements**
- [ ] n8n web interface accessible via https://n8n.improvemyrankings.com
- [ ] All 9 workflows imported and operational
- [ ] HubSpot webhooks receiving and processing correctly
- [ ] Google OAuth authentication flows working
- [ ] AWS SES email sending operational
- [ ] Automated backup system running on Windows schedule

### **Performance Requirements**
- [ ] Workflow execution times comparable to Mac development system
- [ ] Container startup time under 60 seconds
- [ ] External webhook response time under 5 seconds
- [ ] System resource utilization under 70% during normal operation

### **Security Requirements**
- [ ] HTTPS enforcement and SSL certificate validation
- [ ] Basic authentication protecting admin interface
- [ ] Secure credential storage and encryption
- [ ] Windows Firewall properly configured
- [ ] Regular security updates and patch management

### **Operational Requirements**
- [ ] Windows Service auto-start on system boot
- [ ] Automated daily backups with 7-day retention
- [ ] Health monitoring and alerting configured
- [ ] Documentation updated with Windows-specific procedures
- [ ] Rollback procedures tested and documented

---

## 🚨 RISK MITIGATION

### **High-Risk Areas**
1. **OAuth Callback URLs**: Ensure consistent external URLs for Google and HubSpot integrations
2. **Cloudflare Tunnel**: Validate tunnel configuration and certificate management
3. **Data Migration**: Ensure complete workflow and credential transfer
4. **Windows Service**: Verify automatic startup and recovery procedures

### **Contingency Plans**
1. **Rollback Strategy**: Maintain Mac development system as fallback
2. **Data Recovery**: Multiple backup copies and restoration procedures
3. **Network Failover**: Alternative tunnel configuration if primary fails
4. **Service Recovery**: Manual startup procedures if Windows Service fails

---

## 📞 STAKEHOLDER COMMUNICATION

### **Deployment Timeline**
- **Phase 1 (Infrastructure)**: 1-2 days
- **Phase 2 (Network/Tunnel)**: 1 day
- **Phase 3 (Service Deployment)**: 1 day
- **Phase 4 (Migration/Testing)**: 2-3 days
- **Total Estimated Duration**: 5-7 days

### **Communication Plan**
- Daily status updates during deployment
- Immediate notification of any critical issues
- Post-deployment performance and stability report
- Documentation handover and training session

---

## 📝 DELIVERABLES

1. **Operational Windows Production System**
   - n8n running as Windows Service
   - All integrations functional and tested
   - Monitoring and backup systems operational

2. **Updated Documentation**
   - Windows-specific deployment procedures
   - Troubleshooting guides and runbooks
   - Performance baselines and monitoring procedures

3. **Knowledge Transfer**
   - Consolidated architectural insights from all LLM interactions
   - Windows deployment lessons learned
   - Best practices and optimization recommendations

---

**Work Order Status**: 🟡 **READY FOR EXECUTION**  
**Next Action**: Execute LLM knowledge extraction queries and begin Phase 1 infrastructure preparation  
**Assigned To**: Deployment Team  
**Review Date**: Upon completion of each phase  

---

*This work order serves as both a deployment plan and a knowledge extraction tool to ensure we leverage all architectural insights gained during the Mac development phase for a successful Windows production deployment.*
