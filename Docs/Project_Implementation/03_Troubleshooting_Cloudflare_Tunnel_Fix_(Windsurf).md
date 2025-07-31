# n8n Self-Hosting with Docker and Cloudflare Tunnel: A Setup Guide

---
*Document created by Cascade, an agentic AI coding assistant from Windsurf.*
*Role: Resolved Cloudflare Tunnel configuration issues and documented the solution.*
*Date: 2025-07-14T17:34:43-07:00*
---

## 1. Overview

This document details the successful configuration for self-hosting an n8n instance using Docker Compose and exposing it securely to the internet via a Cloudflare Tunnel. The primary challenge encountered during setup was a persistent `error parsing YAML in config file... is a directory` from the `cloudflared` container, despite the Docker Compose file appearing to mount the configuration correctly.

This guide explains the root cause of the issue, the steps taken to resolve it, and a breakdown of the final, working configuration.

---

## 2. The Core Problem & The Fix

The issue stemmed from two main sources:

1.  **A Misconfigured Host File:** The `config.yml` inside the `~/.cloudflared` directory on the host machine was accidentally a **directory**, not a file. This was the root cause of the `is a directory` error. Docker cannot mount a directory as a file, which caused the `cloudflared` service to fail when reading its configuration.

2.  **Overly Complex Docker Configuration:** The `docker-compose.yml` was using a non-standard approach with individual file mounts, unnecessary environment variables, and explicit command flags. This made the setup brittle and harder to debug.

### The Solution

The fix was a three-step process:

1.  **Correct the Host Configuration:** We identified that `~/.cloudflared/config.yml` was a directory and replaced it with a proper YAML file.
2.  **Update `config.yml` Paths:** The new `config.yml` was written to use paths that would be valid *inside* the Docker container (e.g., `/etc/cloudflared/credentials.json`) instead of absolute host paths.
3.  **Simplify `docker-compose.yml`:** The `cloudflared` service definition was simplified to follow the standard practice for the `cloudflare/cloudflared` image, which is to mount the entire configuration directory.

---

## 3. Final Working Configuration

Here is a breakdown of the final, working files and an explanation of why this setup is robust.

### `~/.cloudflared/config.yml`

This file now correctly points to the credentials file as it exists *inside the container*.

```yaml
tunnel: 400f107a-e096-427a-9f00-e5c66a65be4c
credentials-file: /etc/cloudflared/400f107a-e096-427a-9f00-e5c66a65be4c.json

ingress:
  - hostname: n8n.improvemyrankings.com
    service: http://n8n:5678
  - service: http_status:404
```

**Key Points:**
*   `credentials-file`: The path `/etc/cloudflared/...` matches the default location inside the container where we mount the configuration.
*   `service`: The service URL `http://n8n:5678` works because Docker Compose creates a network where services can reach each other by their service name (`n8n`).

### `docker-compose.yml`

The `cloudflared` service is now much simpler and more idiomatic.

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
      - N8N_DEFAULT_WEBHOOK_TIMEOUT=120000
      - N8N_TIMEOUT_THRESHOLD=300
      - DB_TYPE=sqlite
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

**Key Points:**
*   **`volumes`**: We now mount the entire host directory `/Users/henrygroman/.cloudflared` to the container's default configuration directory `/etc/cloudflared`. This is the standard, recommended practice. It automatically brings in `cert.pem`, the tunnel credentials `.json` file, and `config.yml`.
*   **`command`**: The command is simplified to `tunnel run`. The `cloudflared` process automatically looks for `config.yml` in `/etc/cloudflared`, finds it, and reads the tunnel ID from there.
*   **No Environment Variables**: The unnecessary `TUNNEL_*` environment variables were removed, as the configuration is now handled entirely by the `config.yml` file.

This simplified and corrected configuration is more robust, easier to understand, and aligns with the official documentation and best practices for the `cloudflare/cloudflared` Docker image.
