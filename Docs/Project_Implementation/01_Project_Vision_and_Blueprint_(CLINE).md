# n8n Self‑Hosting Project Report

A consolidated reference covering all information gathered so far. Use this as the single source of truth while we prototype on the MacBook Pro and later migrate to the office tower PC.

---

## 1 ▸ Hardware & Software Environment

| Device | Key Specs | OS & Tooling | Role |
| ------ | --------- | ------------ | ---- |
|        |           |              |      |

| **MacBook Pro** (Model MNWA3LL/A) | Apple M2 Max • 12‑core (8P + 4E) • 32 GB RAM | macOS 15.5 · Docker Desktop 4.42.1 (Apple Silicon) · Homebrew (with PostgreSQL 14, Node LTS, FFmpeg) | Local dev / beta tests |
| --------------------------------- | -------------------------------------------- | ---------------------------------------------------------------------------------------------------- | ---------------------- |
| **Office PC 1 – “TrustandObey”**  | Intel i5‑4460 @ 3.20 GHz • 16 GB RAM         | Windows 11 RTM · Docker Desktop (to install)                                                         | 24 × 7 production host |
| **Office PC 2 – “7T”**            | Intel i3‑7130U @ 2.70 GHz • 16 GB RAM        | Windows 11 22H2 · Docker Desktop (to install)                                                        | Backup / overflow      |

**Networking tools**: Tailscale mesh VPN (all devices), Ngrok (for local HTTPS tunnels – to be installed), Traefik (reverse‑proxy & SSL in prod).

---

## 2 ▸ Domain, DNS & Networking Preferences

- **Domain registrar / DNS**: SiteGround / Cloudflare — domain **improvemyrankings.com**.
- **Planned sub‑domain**: **n8n.improvemyrankings.com**\
   ↳ Configured via Cloudflare Tunnel.
- **Exposure strategy**
  - **Dev / Mac** – Cloudflare Tunnel → HTTPS callbacks for HubSpot & Google.
  - **Prod / Tower PC** – Cloudflare Tunnel (zero‑trust, no open ports).
- **Security notes**: enable n8n basic‑auth in prod; back‑up `/home/node/.n8n` volume; Tailscale for private admin access.
- **AWS SES Region**: `us-west-2` (Oregon) for consolidated SES assets.

---

## 3 ▸ HubSpot Integration & Past Roadblocks

- **Legacy pain**: “Insufficient scopes” OAuth error with an old developer account + localhost redirect not accepted by HubSpot.
- **Fix**: Fresh developer account & app — **App ID 15976984**, **Client ID ca2a9792‑3580‑4607‑a0f4‑2a94690d3992** — all scopes enabled.
- **Final Solution**: Connection established using a **HubSpot Private App Token** (`HubSpot Token 4 Last Apple Biz`).
- **Redirect URIs**
  - Cloud: `https://oauth.n8n.cloud/oauth2/callback` (working)
  - Dev: `https://n8n.improvemyrankings.com/rest/oauth2-credential/callback` (via Cloudflare Tunnel).
  - Prod: `https://n8n.lastapple.com/rest/oauth2-credential/callback`.
- **Active workflow (cloud)**
  - **Trigger** – HubSpot *Contact Property Changed* → field **Strategic Outreach** (dropdown: AI Consulting, Reconnect, etc.).
  - **Action** – Gmail “Send message” (static alert, OAuth2).
- **Planned enhancements**
  - Branch on dropdown value → **Amazon SES** email via Beefree template; inject dynamic placeholders (first name, domain).
  - Use expressions: `{{$json["object"].properties.firstname}}` etc.

---

## 4 ▸ Planned Workflows & Integrations

| #    | Purpose                                                                     | Trigger ↔ Action chain                                                                                             | Notes                                       |
| ---- | --------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ | ------------------------------------------- |
| 1    | **Strategic Outreach Alerts**                                               | HubSpot property change ⇒ Get Contact ⇒ AWS SES email (Templated)                                                  | Low volume, real‑time via webhook           |
| 2    | **Competitor Intel Collector**                                              | Gmail label **“Competitor Alerts”** (poll 5 min) ⇒ AI summary (OpenAI / Claude) ⇒ Google Drive doc ⇒ relabel email | Folder‑ID workaround fixes Drive‑root issue |
| 3…20 | Future low‑demand automations (e.g. Google Sheets sync, AI lead enrichment) | TBD                                                                                                                | Target < 50 executions / day                |

**Expected load**: ≤ 20 workflows, mostly webhook‑based or light polls, well within single‑instance capacity on both Mac & Tower PC.

---

## 5 ▸ Insights & Recommendations from Previous Chats

| Source         | Key Take‑aways incorporated                                                                                                            |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------- |
| **Grok**       | Prioritise DNS early, Traefik template, pros/cons table in original hand‑off.                                                          |
| **Perplexity** | `N8N_WEBHOOK_TUNNEL_URL` env, export/import steps, Drive folder workaround, webhook vs. polling guidance, troubleshooting checklist.   |
| **Claude**     | Core env‑vars (`WEBHOOK_URL`, `N8N_HOST`, secure cookies), compose restart policy, timeout increase, AI summarisation pipeline recipe. |
| **Another AI** | AWS SES cleanup, IAM policy for `ses:SendTemplatedEmail`, HubSpot Private App Token, `JSON.stringify({})` for empty template data.    |

### Final configuration nuggets

```env
# Core
N8N_HOST=n8n
N8N_PROTOCOL=https
N8N_PORT=5678
N8N_EDITOR_BASE_URL=https://n8n.improvemyrankings.com
WEBHOOK_URL=https://n8n.improvemyrankings.com
N8N_WEBHOOK_TUNNEL_URL=https://n8n.improvemyrankings.com
# Optional hard time‑out bump
N8N_DEFAULT_WEBHOOK_TIMEOUT=120000
```

---

## Next Steps

1. **Phase 1: Prototype on Mac (COMPLETED)**\
   Successfully set up n8n locally using Docker Compose and exposed it via Cloudflare Tunnel at `https://n8n.improvemyrankings.com`. HubSpot and Gmail integrations are configured and tested.

2. **Phase 2: Enhance Workflows (COMPLETED)**\
   Successfully configured AWS SES integration, enhanced HubSpot workflow to send templated emails via SES, and debugged common issues.

3. **Phase 3: Production Migration (Current Focus)**\
   a. Set up Docker and PostgreSQL on Windows tower.\
   b. Configure Cloudflare Tunnel for the production server.\
   c. Migrate n8n configuration and re-authenticate credentials.

4. **Document** – Export any new workflows, keep this report + hardware / software / networking docs synced in project folder.

---

*Prepared on 2025‑07‑13 — reflects all data supplied to date.*
