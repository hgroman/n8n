# n8n Self-Hosting Master Guide: Docker & Cloudflare Tunnel

This guide provides a comprehensive, step-by-step walkthrough for setting up a self-hosted n8n instance using Docker Compose and exposing it securely via a Cloudflare Tunnel. It incorporates key learnings and troubleshooting steps from a real-world implementation, ensuring a robust and stable setup.

## 1. Prerequisites

Before you begin, ensure you have the following installed and configured:

*   **Docker Desktop:** Essential for running n8n and Cloudflare Tunnel in containers.
*   **Homebrew (macOS):** A package manager used to install `cloudflared`.
*   **Cloudflare Account:** An active Cloudflare account with the domain you wish to use (e.g., `improvemyrankings.com`) managed by Cloudflare DNS.

## 2. Cloudflare Tunnel Setup (CLI)

This section guides you through setting up the Cloudflare Tunnel, which will provide a stable, public HTTPS endpoint for your n8n instance.

### 2.1. Install `cloudflared`

Open your terminal and install the `cloudflared` CLI tool using Homebrew:

```bash
brew install cloudflare/cloudflare/cloudflared
```

### 2.2. Authenticate `cloudflared` with your Cloudflare Account

This step links your local `cloudflared` CLI to your Cloudflare account. It will open a browser window for authentication.

```bash
/opt/homebrew/opt/cloudflared/bin/cloudflared tunnel login
```

**Important:** After logging in through the browser, ensure you see a success message in your terminal similar to:
`You have successfully logged in.`
`If you wish to manage an Argo Tunnel, you may now run cloudflared tunnel commands.`
`Your credentials have been saved to: /Users/YOUR_USERNAME/.cloudflared/cert.pem`
Verify that the `cert.pem` file exists in `~/.cloudflared/` by running `ls -l ~/.cloudflared/`. If it's not there, the login was not fully successful.

### 2.3. Create the Cloudflare Tunnel

Create a new tunnel. Replace `n8n-tunnel` with a name of your choice if desired.

```bash
/opt/homebrew/opt/cloudflared/bin/cloudflared tunnel create n8n-tunnel
```

This command will output the Tunnel ID (e.g., `400f107a-e096-427a-9f00-e5c66a65be4c`) and confirm that tunnel credentials have been written to a JSON file in `~/.cloudflared/`. Keep this Tunnel ID handy.

### 2.4. Create `~/.cloudflared/config.yml`

This configuration file tells `cloudflared` how to route incoming traffic. Create the file `~/.cloudflared/config.yml` with the following content. **Replace `400f107a-e096-427a-9f00-e5c66a65be4c` with your actual Tunnel ID** and `n8n.improvemyrankings.com` with your desired n8n subdomain.

```yaml
tunnel: 400f107a-e096-427a-9f00-e5c66a65be4c
credentials-file: /etc/cloudflared/400f107a-e096-427a-9f00-e5c66a65be4c.json

ingress:
  - hostname: n8n.improvemyrankings.com
    service: http://n8n:5678
  - service: http_status:404
```

**Explanation:**
*   `tunnel`: Your unique Tunnel ID.
*   `credentials-file`: Points to the tunnel's credentials file, which will be mounted into the container.
*   `hostname`: The public domain you want to use for n8n.
*   `service: http://n8n:5678`: This tells `cloudflared` to forward traffic to the `n8n` service (which is the Docker Compose service name) on port `5678` within the Docker network.

### 2.5. Route DNS to the Tunnel

This command creates a CNAME record in your Cloudflare DNS settings, linking your chosen subdomain to the Cloudflare Tunnel.

```bash
/opt/homebrew/opt/cloudflared/bin/cloudflared tunnel route dns n8n-tunnel n8n.improvemyrankings.com
```

## 3. n8n Docker Compose Setup

Now, you'll set up your `docker-compose.yml` to run both n8n and the `cloudflared` tunnel as services.

### 3.1. Create `n8n-local/docker-compose.yml`

Create a directory named `n8n-local` (or your preferred project directory) and inside it, create the `docker-compose.yml` file with the following content. **Ensure you replace `n8n.improvemyrankings.com` with your actual domain.**

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
      - N8N_WEBHOOK_TUNNEL_URL=https://n8n.improvemyrankings.com # Use your Cloudflare domain here
      - N8N_SECURE_COOKIE=false
      - N8N_BASIC_AUTH_ACTIVE=true
      - N8N_BASIC_AUTH_USER=admin
      - N8N_BASIC_AUTH_PASSWORD=admin # CHANGE THIS IN PRODUCTION!
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
      - /Users/YOUR_USERNAME/.cloudflared:/etc/cloudflared # Mount your host's .cloudflared directory
    depends_on:
      - n8n
    networks:
      - default

volumes:
  n8n_data:
```

**Key Points:**
*   **`n8n` Service:** Configured to use `https` and your Cloudflare domain for its base URLs and webhooks. It refers to itself as `n8n` within the Docker network.
*   **`cloudflared` Service:**
    *   `command: tunnel run`: `cloudflared` automatically finds `config.yml` and credentials in `/etc/cloudflared` (due to the volume mount).
    *   `volumes: - /Users/YOUR_USERNAME/.cloudflared:/etc/cloudflared`: This is the crucial mount. It maps your host's `~/.cloudflared` directory (containing `cert.pem`, tunnel JSON, and `config.yml`) directly to `/etc/cloudflared` inside the container. This is the standard and most reliable way to provide `cloudflared` with its necessary files.
    *   `depends_on: - n8n`: Ensures n8n starts before `cloudflared`.
    *   `networks: - default`: Ensures both services are on the same Docker network and can communicate.

## 4. Launch n8n and Cloudflare Tunnel

Navigate to your `n8n-local` directory in the terminal and start the Docker Compose stack:

```bash
cd n8n-local
docker-compose up -d
```

This will pull the necessary Docker images (if not already present), create the `n8n_data` volume, and start both the `n8n` and `cloudflared` containers.

## 5. Initial n8n Access and Workflow Testing

1.  **Access n8n UI:** Open your web browser and navigate to `https://n8n.improvemyrankings.com`. You should see the n8n "Set up owner account" page.
2.  **Create Owner Account:** Follow the prompts to create your admin user.
3.  **Update OAuth/Webhook Endpoints:** For any external services (like HubSpot or Gmail) that use OAuth or webhooks, update their redirect URIs and webhook URLs to `https://n8n.improvemyrankings.com/rest/oauth2-credential/callback` (for OAuth) or `https://n8n.improvemyrankings.com/webhook/YOUR_WEBHOOK_PATH` (for webhooks).
4.  **Re-authenticate Credentials:** In n8n, go to **Credentials**, select your HubSpot/Gmail OAuth credentials, and click "Connect" to re-authenticate using the new public URL.
5.  **Test Workflows:** Import your existing workflows (e.g., `HubSpot - Strategic Outreach Monitor.json`) and test them to ensure they trigger and execute correctly.

## 6. Troubleshooting Tips

*   **`cloudflared tunnel login` fails or `cert.pem` is missing:** Ensure you complete the entire browser authentication flow. If issues persist, check file permissions on `~/.cloudflared/`.
*   **`error parsing YAML in config file... is a directory`:** This means your `~/.cloudflared/config.yml` on the host is actually a directory, not a file. Delete the directory and create it as a proper YAML file.
*   **Cloudflare Error 1033 (Tunnel unable to resolve host):**
    *   Verify `cloudflared` container logs for any errors.
    *   Ensure `config.yml` has `service: http://n8n:5678` (or whatever your n8n service name is) and not `localhost`.
    *   Confirm the DNS record for `n8n.improvemyrankings.com` is correctly pointing to the Cloudflare Tunnel.
*   **`ngrok` instability:** This guide replaces `ngrok` with Cloudflare Tunnel for stability. If you still encounter `ngrok` issues, it's a sign to fully transition to the Cloudflare setup.

This guide should provide a solid foundation for your self-hosted n8n instance.
