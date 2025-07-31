# n8n Self-Hosting: The Complete Setup Guide

---
*Document created by Cascade, an agentic AI coding assistant from Windsurf.*
*Role: Resolved Cloudflare Tunnel configuration issues, guided Google OAuth credential setup, and documented the complete solution.*
*Date: 2025-07-14T17:34:43-07:00*
---

## 1. Overview

This document is the master guide for the self-hosted n8n instance running on Docker and exposed via a Cloudflare Tunnel. It covers the full stack, from the server and network configuration to the application-level credentials for Google services. This guide consolidates all the steps taken to create a stable, persistent, and fully functional n8n environment.

---

## 2. Core Infrastructure: Docker & Cloudflare Tunnel

The foundation of this setup is running n8n and its corresponding Cloudflare Tunnel as services in Docker Compose. The primary challenge overcome was a misconfiguration in the Cloudflare setup.

### The Problem: `is a directory` Error

The `cloudflared` container was failing because `~/.cloudflared/config.yml` on the host machine was accidentally a directory, not a file. This caused Docker's volume mount to fail.

### The Solution: Simplification and Correction

1.  **Fixed Host Files:** The incorrect `~/.cloudflared/config.yml` directory was removed and replaced with a proper YAML file.
2.  **Simplified `docker-compose.yml`:** The configuration was updated to use a single, direct mount of the entire `~/.cloudflared` directory to the container's standard `/etc/cloudflared` path. This is the official, recommended practice.

### Final `docker-compose.yml`

```yaml
version: '3.7'

services:
  n8n:
    image: n8nio/n8n:latest
    restart: unless-stopped
    ports:
      - "5678:5678"
    environment:
      - N8N_PROTOCOL=https
      - N8N_HOST=n8n
      - N8N_PORT=5678
      - N8N_EDITOR_BASE_URL=https://n8n.improvemyrankings.com
      - WEBHOOK_URL=https://n8n.improvemyrankings.com
      - N8N_WEBHOOK_TUNNEL_URL=https://n8n.improvemyrankings.com
      - N8N_SECURE_COOKIE=false
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=admin # Placeholder
    volumes:
      - n8n_data:/home/node/.n8n

  cloudflared:
    image: cloudflare/cloudflared
    restart: unless-stopped
    command: tunnel run
    volumes:
      - /Users/henrygroman/.cloudflared:/etc/cloudflared
    depends_on:
      - n8n

volumes:
  n8n_data:
```

### Final `~/.cloudflared/config.yml`

```yaml
tunnel: 400f107a-e096-427a-9f00-e5c66a65be4c
credentials-file: /etc/cloudflared/400f107a-e096-427a-9f00-e5c66a65be4c.json

ingress:
  - hostname: n8n.improvemyrankings.com
    service: http://n8n:5678
  - service: http_status:404
```

---

## 3. Data Persistence: Your Data is Safe

Your workflows, credentials, and execution history **are safe** and **will persist** even if you restart the containers or your computer. This is achieved using a Docker **named volume**.

*   **How it works:** The `volumes: - n8n_data:/home/node/.n8n` line in the `docker-compose.yml` file tells Docker to map the n8n container's internal data directory to a managed volume named `n8n_data`.
*   **Result:** This volume exists on your Mac's filesystem, separate from the container. When the container is removed, the volume remains. When a new container starts, it re-attaches to the existing volume, and all your data is instantly available.

---

## 4. Google Integration: OAuth 2.0 Credentials

To allow n8n to send emails via Gmail, we configured OAuth 2.0 credentials in the Google Cloud Platform.

### Summary of Steps:

1.  **Project Selection:** We used your existing "scraper sky" project in the Google Cloud Console.
2.  **API Enablement:** The **Gmail API** was enabled from the API Library.
3.  **OAuth Consent Screen:**
    *   An OAuth consent screen was configured with the **User Type** set to **External**.
    *   App information (name, support email) was provided.
    *   The necessary **scope** (`.../auth/gmail.send`) was added to allow n8n to send emails.
    *   Your Google account was added as a **Test User**.
4.  **Credential Creation:**
    *   An **OAuth 2.0 Client ID** was created.
    *   The **Application Type** was set to **Web application**.
    *   The crucial **Authorized redirect URI** was set to your n8n instance's callback URL: `https://n8n.improvemyrankings.com/rest/oauth2-credential/callback`.
5.  **n8n Configuration:**
    *   The generated **Client ID** and **Client Secret** were copied from the Google Cloud Console.
    *   A new **Google OAuth2 API** credential was created within the n8n UI.
    *   The Client ID and Secret were pasted into n8n, and the connection was authorized by signing in with your Google account.

This completes the end-to-end setup. Your n8n instance is now securely exposed to the internet, your data is persistent, and it is fully authorized to connect to Google services.
