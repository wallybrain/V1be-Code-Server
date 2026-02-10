# V1be Code Server

## Overview
Caddy reverse proxy serving multiple services at `example.com` and subdomains, with auto-SSL via Let's Encrypt. Code-server runs natively on the host (not in Docker), so the VS Code terminal provides the full `lwb3` toolset.

## Architecture
```
Internet -> example.com          -> Caddy -> Static Semantic Training site (public, /srv/semantic-training)
                                                 -> wallybrain-music (/music routes, container DNS :8800)
                                                 -> wallybrain-music + Authelia (/music/admin, 2FA required)
         -> code.example.com     -> Caddy -> Authelia (forward_auth) -> code-server (host.docker.internal:8080)
         -> auth.example.com     -> Caddy -> Authelia portal (container DNS :9091)
         -> ollama.example.com   -> Caddy -> Ollama (host.docker.internal:11434, bearer token auth)
```

## Stack
| Service | How it runs | Purpose |
|---------|-------------|---------|
| `code-server` | Systemd user service (`~/.local/lib/code-server-4.108.2/`) | VS Code in browser |
| `caddy` | Docker (`caddy:2-alpine`, webproxy network, `init: true`) | Reverse proxy, auto Let's Encrypt SSL |
| `authelia` | Docker (`authelia/authelia:latest`, webproxy network) | Authentication portal with TOTP 2FA |

### Why code-server is native (not Docker)
Running code-server directly on the host means the VS Code terminal is a real `lwb3` shell with access to docker, git, node, python, ollama, and all installed tools. Previously it ran in a container with a minimal Debian toolset and required SSH to reach the host.

### Why Caddy uses Docker port mappings (not host network)
Docker's port mappings (`-p 80:80`) create iptables DNAT rules in the FORWARD chain, which bypass Hostinger's host firewall. Using `network_mode: host` routes traffic through the INPUT chain instead, which Hostinger blocks. Caddy stays on the `webproxy` Docker network for container DNS resolution (authelia, wallybrain-music) and uses `host.docker.internal` to reach the native code-server.

### Container-to-host networking
Docker containers cannot reach the host on arbitrary ports by default (Hostinger's firewall blocks INPUT from bridge interfaces). The `fix-iptables.sh` script adds rules to allow traffic from the webproxy bridge (`br-XXXXXXXXXXXX`) to host ports 8080 (code-server) and 11434 (Ollama), and also DROPs external (eth0) traffic to ports 8080, 11434, and 9999 so these services are only reachable via Caddy or localhost. A systemd service runs this at boot. The `init: true` flag on Caddy prevents zombie `ssl_client` processes from BusyBox `wget` healthchecks.

### Ollama integration
Ollama runs natively on the host (port 11434). It's exposed externally via `ollama.example.com` through Caddy with bearer token auth (`OLLAMA_API_KEY` in `.env`). Continue.dev (v1.3.30) connects to Ollama directly at `http://localhost:11434` since code-server runs natively on the host. Config: `~/.continue/config.yaml`. Note: CPU-only inference on this VPS is slow — functional demo only. Consider adding a cloud model provider for interactive use.

### Caddy health check
Uses the admin API (`http://127.0.0.1:2019/config/`) instead of port 80. Port 80 triggers an HTTP→HTTPS redirect that BusyBox `wget` can't follow (no `--no-check-certificate`). The admin API also only listens on IPv4, so the health check must use `127.0.0.1` not `localhost` (BusyBox resolves to IPv6 first).

## Authentication Flow
1. User visits `code.example.com`
2. Caddy `forward_auth` checks with Authelia
3. If unauthenticated, redirects to `auth.example.com`
4. User enters password + TOTP code from authenticator app
5. Authelia sets session cookie, Caddy proxies to code-server

Note: `example.com` (the root domain) is now a public static site (Semantic Training framework). The IDE link on that page navigates to `code.example.com`.

## Files
| File | Purpose |
|------|---------|
| `docker-compose.yml` | Caddy + Authelia containers (webproxy network) |
| `Caddyfile` | Reverse proxy config with security headers, `.git` blocking, static site at root, code-server on `code.` subdomain |
| `fix-iptables.sh` | iptables rules: ACCEPT bridge→8080/11434, DROP eth0→8080/11434/9999 (runs via privileged container) |
| `SETUP_CONTINUE_OLLAMA.md` | Guide for configuring Continue.dev extension with Ollama (legacy, see config.yaml) |
| `~/.continue/config.yaml` | Continue.dev v1.3.30 config (Ollama via localhost) |
| `.env` | Secrets: password, JWT, session, encryption keys (never commit) |
| `authelia/configuration.yml` | Authelia settings, access control, session config |
| `authelia/users_database.yml` | User accounts with Argon2 hashed passwords |
| `authelia/db.sqlite3` | Authelia state database (auto-created, gitignored) |
| `authelia/notification.txt` | One-time codes for TOTP setup (gitignored) |
| `~/.config/code-server/config.yaml` | Code-server bind address and password |
| `~/.config/systemd/user/code-server.service` | Systemd unit file for code-server |
| `~/.config/systemd/user/fix-iptables.service` | Runs `fix-iptables.sh` on boot |

## Credentials
- Login: username `admin`, password in `.env` as `CODE_SERVER_PASSWORD`
- TOTP registered in your authenticator app
- Authelia secrets in `.env`: JWT, session, and storage encryption keys
- Ollama API key in `.env` as `OLLAMA_API_KEY` (bearer token for ollama.example.com)

## Common Commands
```bash
# Docker (Caddy + Authelia)
docker compose up -d              # Start Caddy + Authelia
docker compose down               # Stop
docker compose restart             # Restart after config changes
docker compose logs -f caddy      # Check SSL cert status
docker compose logs -f authelia   # Check auth issues

# Code-server (systemd)
systemctl --user status code-server   # Check status
systemctl --user restart code-server  # Restart
systemctl --user stop code-server     # Stop
journalctl --user -u code-server -f   # Follow logs

# Iptables fix (after reboot or if container-to-host breaks)
./fix-iptables.sh                     # Re-apply bridge ACCEPT + eth0 DROP rules
systemctl --user status fix-iptables  # Check boot service

# Grab one-time code (for TOTP changes/resets)
docker exec authelia cat /config/notification.txt
```

## DNS Requirements
| Record | Name | Points to |
|--------|------|-----------|
| A | `@` (example.com) | `YOUR_SERVER_IP` |
| A | `auth` (auth.example.com) | `YOUR_SERVER_IP` |
| A | `code` (code.example.com) | `YOUR_SERVER_IP` |
| A | `ollama` (ollama.example.com) | `YOUR_SERVER_IP` |

## Troubleshooting
- **Site unreachable after reboot**: Run `./fix-iptables.sh` — the iptables rule may not have been applied. Check `systemctl --user status fix-iptables`
- **Login button hangs**: Likely rate-limited — `docker compose restart authelia`
- **SSL cert issues**: Check `docker compose logs -f caddy` for ACME errors
- **Need a new one-time code**: `docker exec authelia cat /config/notification.txt`
- **Code-server not responding**: Check `systemctl --user status code-server` and `journalctl --user -u code-server`
- **Terminal missing tools**: Code-server may have reverted to a container — verify with `systemctl --user status code-server`
- **Zombie processes**: Verify `init: true` is set on Caddy in docker-compose.yml. Check with `ps aux | awk '$8 ~ /Z/' | wc -l`
- **Caddy health check unhealthy**: Must use `http://127.0.0.1:2019/config/` (admin API, IPv4). If changed to port 80 or `localhost`, it will fail (HTTPS redirect / IPv6)
- **Ollama 502 from Caddy**: Run `./fix-iptables.sh` to re-open port 11434 on the bridge. Verify with `docker exec caddy wget -qO- http://host.docker.internal:11434`
- **Continue.dev can't reach Ollama**: Check `apiBase` in Continue config points to `https://ollama.example.com` with correct bearer token

## Security Hardening

### Lynis Assessment (2026-02-10) — Score: 79/100
Full audit performed with Lynis and rkhunter. Hardening script at `/home/lwb3/harden.sh` applied 12 remediations, raising the score from 66 → 79.

**What was hardened:**
| Area | Detail |
|------|--------|
| SSH | Key-only auth, no root, drop-in at `/etc/ssh/sshd_config.d/99-lynis-hardening.conf` (AllowTcpForwarding=no, LogLevel=VERBOSE, MaxSessions=2) |
| Firewall | UFW default DROP, only ports 22 + 8567 allowed; iptables DROP eth0→8080/11434/9999 |
| Kernel | sysctl hardened (`/etc/sysctl.d/99-lynis-hardening.conf`) — martian logging, no source routing, kptr_restrict=2, BPF JIT hardened, Docker-safe (forwarding=1) |
| Audit | auditd rules for auth files, sudoers, SSH config, cron, network, firewall changes (`/etc/audit/rules.d/lynis-hardening.rules`) |
| Network | Postfix loopback-only, banner stripped; unused protocols blacklisted (dccp, sctp, rds, tipc) |
| Auth | fail2ban active, libpam-pwquality installed, SHA_CRYPT rounds 5000-10000, umask 027 |
| Integrity | rkhunter + debsums installed, core dumps disabled, legal banners set |
| Headers | Caddy: HSTS, X-Frame-Options DENY, X-Content-Type-Options nosniff, Referrer-Policy |
| Blocking | `.git` and `.env` paths return 404 |

### Automated Security Scanning
Monthly scans via systemd timer — runs rkhunter (rootkit/integrity) and Lynis (hardening audit), logs to `/var/log/security-scan/`, sends Discord alert on score regression or rkhunter warnings.

```bash
# Install the timer
sudo cp security-scan.service security-scan.timer /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now security-scan.timer

# Run manually
sudo bash security-scan.sh

# After apt upgrade — update rkhunter's binary baseline
sudo bash security-scan.sh --update-baseline
```

| File | Purpose |
|------|---------|
| `security-scan.sh` | Runs rkhunter + Lynis, logs results, Discord alerts on regression |
| `security-scan.service` | systemd oneshot unit |
| `security-scan.timer` | Monthly trigger with randomized delay |
| `/home/lwb3/harden.sh` | Original hardening script (12 remediations) |

## Key Lessons (for future reference)
- Docker port mappings bypass host firewalls (FORWARD chain); `network_mode: host` does not (INPUT chain)
- BusyBox `wget` in Alpine spawns `ssl_client` children — use `init: true` to reap them
- Hostinger VPS blocks container-to-host traffic on bridge interfaces by default
- The webproxy bridge interface name (`br-XXXXXXXXXXXX`) may change if the network is recreated — update `fix-iptables.sh` if so
- Caddy health checks in Alpine must use `127.0.0.1` (not `localhost`) and avoid port 80 (HTTPS redirect breaks BusyBox wget)
- Caddy admin API listens on IPv4 only by default — BusyBox resolves `localhost` to IPv6 first
- Caddy `respond` directive runs after `handle` blocks — use `handle` with path matcher to block paths before `file_server`
- Don't bind services to `127.0.0.1` if Docker containers need to reach them via `host.docker.internal` — use iptables DROP on eth0 instead
