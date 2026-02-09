# Home Server Development Environment

A local AI-powered automation platform built on Ubuntu Linux, integrating Claude Code with n8n workflows, local LLM inference, and browser automation.

## Architecture

```
Claude Code CLI
      │
      ├── MCP Servers (stdio transport)
      │   ├── n8n        → Workflow automation
      │   ├── ollama     → Local LLM (llama3.2)
      │   ├── sqlite     → Database queries
      │   ├── playwright → Browser automation
      │   └── exa        → Web search/research
      │
      ├── Docker Stack
      │   ├── n8n (port 8567)
      │   ├── system-stats (port 9998)
      │   ├── container-health (port 9997)
      │   └── cpu-server (port 9999)
      │
      └── Systemd Services
          └── ollama (port 11434)
```

## What's Running

| Service | Port | Purpose |
|---------|------|---------|
| n8n | 8567 | Visual workflow automation |
| Ollama | 11434 | Local LLM inference |
| system-stats | 9998 | CPU/memory/disk metrics |
| container-health | 9997 | Docker container monitoring |
| cpu-server | 9999 | Host CPU monitoring |

## Active Workflows (n8n)

- **CPU Monitor** - Discord alert when CPU ≥ 80%
- **Memory Monitor** - Checks every 5 minutes
- **Disk Monitor** - Checks every 5 minutes
- **Container Health** - Checks every 2 minutes

## MCP Integrations

Claude Code can interact with all services via MCP:

```bash
# Examples of what Claude can do:
- List/create/execute n8n workflows
- Generate text with local Ollama models
- Query SQLite databases
- Automate browser tasks
- Search the web with Exa
```

## Projects

| Directory | Description |
|-----------|-------------|
| `/home/lwb3/n8n-mcp/` | Docker stack for n8n + monitoring services |
| `/home/lwb3/n8n-mcp-server/` | MCP server bridging Claude ↔ n8n |
| `/home/lwb3/ollama-mcp-server/` | MCP server for local LLM inference |
| `/home/lwb3/playwright-mcp/` | Browser automation via Playwright |
| `/home/lwb3/ollama-csound/` | AI-powered sound synthesis |

## Quick Commands

```bash
# View running containers
docker ps

# Check n8n logs
docker logs -f n8n

# Restart the stack
cd /home/lwb3/n8n-mcp && docker compose restart

# Check Ollama status
systemctl status ollama

# List Ollama models
curl http://localhost:11434/api/tags
```

## Configuration

| File | Purpose |
|------|---------|
| `~/.claude/mcp.json` | MCP server definitions |
| `~/.claude/settings.json` | Claude Code hooks & permissions |
| `/home/lwb3/CLAUDE.md` | Project preferences & standards |
| `/home/lwb3/n8n-mcp/.env` | n8n credentials |

## Tech Stack

- **OS**: Ubuntu Linux
- **Runtime**: Node.js 20.20.0, Python 3.12.3
- **Containers**: Docker 29.2.0, Docker Compose
- **LLM**: Ollama with llama3.2:1b
- **Automation**: n8n, Playwright
- **Database**: SQLite
- **Notifications**: Discord webhooks

## Security Notes

- All secrets stored in `.env` files (gitignored)
- Services bound to localhost only
- No public port exposure without auth
- API keys passed via environment variables
