# V1be Code Server - Complete System Inventory

**Generated**: 2026-02-01 | **Platform**: Ubuntu Linux 6.8.0-94-generic

---

## Quick Reference

```
/home/lwb3/
├── Configuration
│   ├── CLAUDE.md                 # Global project standards
│   ├── .claude/mcp.json          # MCP server definitions
│   └── .claude/settings.json     # Hooks & permissions
│
├── MCP Servers (Claude Integration)
│   ├── n8n-mcp-server/           # Workflow automation
│   ├── ollama-mcp-server/        # Local LLM inference
│   ├── sqlite-mcp-server/        # Database queries
│   ├── exa-mcp-server/           # Web search
│   └── playwright-mcp/           # Browser automation
│
├── Docker Infrastructure
│   ├── n8n-mcp/                  # Main stack (n8n + monitoring)
│   └── mcp-servers/              # Containerized MCP servers
│
├── Applications
│   ├── ollama-csound/            # AI sound synthesis
│   ├── ollama-supercollider/     # AI sound synthesis
│   └── apify/                    # Web scraping
│
└── Data
    ├── databases/                # SQLite databases
    └── n8n-mcp/n8n-data/         # n8n persistent data
```

---

## 1. MCP SERVERS

### Overview

| Server | Location | Port/Transport | Tools | Status |
|--------|----------|----------------|-------|--------|
| n8n | `/home/lwb3/n8n-mcp-server/` | stdio → localhost:8567 | 9 | Active |
| ollama | `/home/lwb3/ollama-mcp-server/` | stdio → localhost:11434 | 16 | Active |
| sqlite | `/home/lwb3/sqlite-mcp-server/` | stdio → /home/lwb3/databases/ | 10 | Active |
| exa | `/home/lwb3/exa-mcp-server/` | stdio → Exa API | 9 | Active |
| playwright | `/home/lwb3/playwright-mcp/` | stdio → headless browser | 5 | Active |
| sequential-thinking | npx | stdio | 1 | Active |
| apify | npx | stdio → Apify API | varies | Configured |
| semgrep | Docker | stdio | varies | Configured |

---

### 1.1 N8N MCP Server

```
/home/lwb3/n8n-mcp-server/
├── index.js              # MCP implementation (7.5 KB)
├── package.json          # @modelcontextprotocol/sdk v1.25.3, zod
├── package-lock.json
├── .env                  # N8N_API_KEY
└── node_modules/         # 93 packages
```

**Tools Available**:
- `list_workflows` - List all workflows
- `get_workflow` - Get workflow details
- `create_workflow` - Create new workflow
- `update_workflow` - Modify existing workflow
- `delete_workflow` - Remove workflow
- `activate_workflow` - Toggle activation
- `execute_workflow` - Run workflow manually
- `list_executions` - View execution history
- `get_execution` - Get execution details

**Connection**: `http://localhost:8567` (n8n Docker container)

---

### 1.2 Ollama MCP Server

```
/home/lwb3/ollama-mcp-server/
├── index.js              # MCP implementation (22.7 KB)
├── package.json          # @modelcontextprotocol/sdk v0.5.0
├── package-lock.json
├── CLAUDE.md             # Documentation
├── n8n-ollama-workflow.json  # Sample workflow
├── .env.example
├── .gitignore
└── node_modules/         # 16 packages
```

**Tools Available** (16 total):
- `ollama_generate` - Single prompt completion
- `ollama_chat` - Multi-turn conversation
- `ollama_list_models` - List installed models
- `ollama_pull_model` - Download new model
- `ollama_translate` - Multilingual translation
- `ollama_code_review` - Code analysis
- `ollama_embeddings` - Generate embeddings
- Plus 9 additional specialized tools

**Connection**: `http://localhost:11434` (Ollama systemd service)

**Model Installed**: `llama3.2:1b` (1.3 GB)

---

### 1.3 SQLite MCP Server

```
/home/lwb3/sqlite-mcp-server/
├── index.js              # MCP implementation (13.4 KB)
├── package.json          # better-sqlite3 v12.6.2
├── package-lock.json
└── node_modules/         # 128 packages
```

**Tools Available** (10 total):
- Database query execution
- Table listing
- Schema inspection
- Data manipulation

**Connection**: `/home/lwb3/databases/` directory

---

### 1.4 Exa MCP Server

```
/home/lwb3/exa-mcp-server/
├── src/                  # TypeScript source
├── api/                  # API layer
├── skills/               # Tool definitions
│   ├── company-search/
│   ├── x-search/
│   ├── people-search/
│   └── research-paper-search/
├── package.json          # v3.1.7
├── Dockerfile
├── README.md
├── VERCEL_DEPLOYMENT_GUIDE.md
├── tsconfig.json
├── smithery.yaml
└── node_modules/
```

**Tools Available**:
- `web_search_exa` - General web search
- `get_code_context_exa` - Code/documentation search
- `company_research_exa` - Company research
- Deep search, crawling, people search (configurable)

**Connection**: Exa API (requires `EXA_API_KEY`)

---

### 1.5 Playwright MCP

```
/home/lwb3/playwright-mcp/
└── CLAUDE.md             # Documentation
```

**Package**: `@playwright/mcp` (via npx)

**Tools Available**:
- `browser_navigate` - Go to URL
- `browser_click` - Click element
- `browser_type` - Type into input
- `browser_snapshot` - Get accessibility tree
- `browser_screenshot` - Capture page

**Browser**: Chromium (cached at `~/.cache/ms-playwright/`)

---

### 1.6 MCP Configuration

**File**: `~/.claude/mcp.json`

```json
{
  "mcpServers": {
    "n8n": {
      "command": "node",
      "args": ["/home/lwb3/n8n-mcp-server/index.js"],
      "env": { "N8N_URL": "http://localhost:8567", "N8N_API_KEY": "..." }
    },
    "ollama": {
      "command": "node",
      "args": ["/home/lwb3/ollama-mcp-server/index.js"],
      "env": { "OLLAMA_URL": "http://localhost:11434" }
    },
    "sqlite": {
      "command": "node",
      "args": ["/home/lwb3/sqlite-mcp-server/index.js"]
    },
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp"]
    },
    "sequential-thinking": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-sequential-thinking"]
    },
    "apify": {
      "command": "npx",
      "args": ["-y", "@apify/actors-mcp-server"],
      "env": { "APIFY_TOKEN": "..." }
    },
    "semgrep": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "ghcr.io/semgrep/mcp", "-t", "stdio"]
    }
  }
}
```

---

## 2. DOCKER INFRASTRUCTURE

### 2.1 Main Stack (n8n + Monitoring)

**Location**: `/home/lwb3/n8n-mcp/`

```
/home/lwb3/n8n-mcp/
├── docker-compose.yml    # Stack definition
├── CLAUDE.md             # Documentation
├── system-stats.js       # System metrics service
├── container-health.js   # Container health monitor
├── cpu-monitor.sh        # CPU monitoring script
├── backup.sh             # Backup script
├── n8n-data/             # Persistent data (27 MB)
│   ├── database.sqlite
│   ├── database.sqlite-wal
│   ├── database.sqlite-shm
│   ├── n8nEventLog*.log
│   └── binaryData/
├── backups/
└── venv/                 # Python virtual env
```

**Running Containers**:

| Container | Image | Port | Purpose | Status |
|-----------|-------|------|---------|--------|
| n8n | n8nio/n8n:latest | 8567 | Workflow automation | Running |
| system-stats | node:20-alpine | 9998 | CPU/memory/disk metrics | Running |
| container-health | node:20-alpine | 9997 | Docker monitoring | Running |
| cpu-server | node:20-slim | 9999 | Host CPU monitoring | Running |

**Active n8n Workflows**:

| Workflow | Frequency | Trigger | Action |
|----------|-----------|---------|--------|
| CPU Monitor | 1 min | CPU ≥ 80% | Discord alert |
| Memory Monitor | 5 min | Memory ≥ 80% | Discord alert |
| Disk Monitor | 5 min | Disk ≥ 80% | Discord alert |
| Container Health | 2 min | Container unhealthy | Discord alert |

---

### 2.2 MCP Servers Stack (Containerized)

**Location**: `/home/lwb3/mcp-servers/`

```
/home/lwb3/mcp-servers/
├── docker-compose.yml    # Unified compose
├── CLAUDE.md             # Documentation
├── Dockerfile.node       # Node.js MCP template
├── Dockerfile.sqlite     # SQLite MCP template
├── .env                  # API keys
└── .env.example
```

**Services** (build-ready):
- `n8n-mcp` - Containerized n8n MCP server
- `ollama-mcp` - Containerized Ollama MCP server
- `sqlite-mcp` - Containerized SQLite MCP server
- `exa-mcp` - Containerized Exa MCP server

**Network**: `mcp-network`

---

## 3. SYSTEMD SERVICES

### 3.1 Ollama Service

**Status**: Active (running)

```
Service: ollama.service
Executable: /usr/local/bin/ollama serve
Port: 127.0.0.1:11434
Memory: 1.4 GB (peak 2.9 GB)
Model: llama3.2:1b (1.3 GB)
```

**Commands**:
```bash
systemctl status ollama    # Check status
systemctl restart ollama   # Restart service
curl localhost:11434/api/tags  # List models
```

---

## 4. APPLICATIONS

### 4.1 AI Sound Synthesis (Csound)

**Location**: `/home/lwb3/ollama-csound/`

```
/home/lwb3/ollama-csound/
├── CLAUDE.md             # Documentation
├── generate.py           # Generator script (10.2 KB)
└── output/               # Generated WAV files
    ├── sound.csd
    └── sound.wav
```

**Workflow**:
1. User describes sound → "deep bass drone"
2. Ollama extracts parameters → frequency=55, amplitude=0.8
3. Csound renders → WAV file

**Sound Templates**: bell, bass, pad, noise, pluck, FM, sine

---

### 4.2 AI Sound Synthesis (SuperCollider)

**Location**: `/home/lwb3/ollama-supercollider/`

```
/home/lwb3/ollama-supercollider/
├── generate.py           # Generator script (8.5 KB)
└── output/
    └── sound.scd
```

---

### 4.3 Apify Integration

**Location**: `/home/lwb3/apify/`

```
/home/lwb3/apify/
├── CLAUDE.md             # Documentation
└── .env                  # Apify token
```

**CLI Auth**: `~/.apify/auth.json`

---

### 4.4 Games

**Location**: `/home/lwb3/games/`

```
/home/lwb3/games/
├── zork1-r119-s880429.z3
├── zork1.z3              # 84.9 KB
└── zork1.z5
```

---

## 5. DATA STORAGE

### 5.1 Databases

```
/home/lwb3/databases/
└── test.db               # SQLite test database (12.3 KB)
```

### 5.2 N8N Data

```
/home/lwb3/n8n-mcp/n8n-data/   # 27 MB total
├── database.sqlite       # Main database (12.6 MB)
├── database.sqlite-wal   # Write-ahead log (4.1 MB)
├── database.sqlite-shm   # Shared memory (32 KB)
├── n8nEventLog*.log      # Event logs (5.5 MB)
├── config
└── binaryData/
```

---

## 6. CONFIGURATION

### 6.1 Claude Code Configuration

```
~/.claude/
├── mcp.json              # MCP server definitions (ACTIVE)
├── settings.json         # Hooks & permissions (ACTIVE)
├── settings.local.json   # Local overrides
├── memory.md             # Session memory
├── history.jsonl         # Command history
├── .credentials.json     # Auth credentials
├── hooks/
│   └── log-activity.sh   # Activity logging hook
├── cache/
├── debug/
├── file-history/         # Edit history (21 dirs)
├── plans/
├── plugins/
├── projects/
├── session-env/          # Session environments (26 dirs)
├── shell-snapshots/
├── statsig/
└── todos/
```

### 6.2 Activity Logging Hook

**File**: `~/.claude/hooks/log-activity.sh`

Logs all tool usage to `/var/log/claude-code/activity.log`:
- Timestamp
- Event type (preToolUse/postToolUse)
- JSON data

---

## 7. NETWORK & PORTS

| Port | Service | Address | Type |
|------|---------|---------|------|
| 22 | SSH | 0.0.0.0 | Server |
| 8567 | n8n | 0.0.0.0 | HTTP |
| 9997 | container-health | 0.0.0.0 | HTTP |
| 9998 | system-stats | 0.0.0.0 | HTTP |
| 9999 | cpu-server | 0.0.0.0 | HTTP |
| 11434 | Ollama | 127.0.0.1 | HTTP |

---

## 8. CREDENTIALS LOCATIONS

| Secret | Location | Notes |
|--------|----------|-------|
| n8n API Key | `/home/lwb3/n8n-mcp-server/.env` | MCP server |
| Apify Token | `/home/lwb3/apify/.env` | Also in docker-compose |
| EXA API Key | `/home/lwb3/mcp-servers/.env` | Exa search |
| Discord Webhook | n8n workflows | Embedded |

**All `.env` files are gitignored**

---

## 9. DATA FLOW DIAGRAMS

### Claude Code Integration

```
Claude Code CLI
      │
      ├──[stdio]──→ n8n MCP ──→ n8n (8567)
      │                            ├──→ CPU monitor
      │                            ├──→ Memory monitor
      │                            ├──→ Disk monitor
      │                            └──→ Discord webhooks
      │
      ├──[stdio]──→ Ollama MCP ──→ Ollama (11434)
      │                              └──→ llama3.2:1b
      │
      ├──[stdio]──→ SQLite MCP ──→ /home/lwb3/databases/
      │
      ├──[stdio]──→ Playwright MCP ──→ Chromium
      │
      └──[stdio]──→ Exa MCP ──→ Web search API
```

### Monitoring & Alerts

```
n8n Workflows (every 1-5 min)
      │
      ├──→ HTTP Request ──→ system-stats:9998
      │                          └──→ CPU/Memory/Disk metrics
      │
      ├──→ HTTP Request ──→ container-health:9997
      │                          └──→ Docker container status
      │
      └──→ IF threshold exceeded
                └──→ Discord Webhook ──→ Discord channel
```

### Sound Synthesis

```
User Input: "deep bass drone"
      │
      └──→ Ollama (llama3.2:1b)
                │
                └──→ Extract parameters
                        │ frequency: 55
                        │ amplitude: 0.8
                        │ duration: 10
                        │
                        └──→ Csound/SuperCollider
                                    │
                                    └──→ /output/sound.wav
```

---

## 10. INSTALLED TOOLS

**Core**: git, node (v20.20.0), npm, python3 (3.12.3), pip3, docker (29.2.0)

**Utilities**: jq, htop, tmux, curl, wget, stress

**CLI Enhancements**: bat, fdfind (fd), rg (ripgrep), ncdu

**Docker Tools**: lazydocker, ctop

**Data Processing**: yq (YAML)

**GitHub**: gh

**AI**: ollama, csound

---

## 11. FUTURE EXPANSION AREAS

Based on current architecture:

- [ ] Add more Ollama models (codellama, mistral)
- [ ] Expand n8n workflows (GitHub integration, scheduled tasks)
- [ ] Add PostgreSQL MCP server
- [ ] Set up backup strategy for Docker volumes
- [ ] Configure log rotation for containers
- [ ] Add authentication to exposed ports
- [ ] Expand sound synthesis templates

---

## 12. QUICK COMMANDS

```bash
# Docker
docker ps                          # Running containers
docker logs -f n8n                 # n8n logs
cd /home/lwb3/n8n-mcp && docker compose restart

# Ollama
systemctl status ollama
curl localhost:11434/api/tags      # List models
curl localhost:11434/api/generate -d '{"model":"llama3.2:1b","prompt":"hello"}'

# System stats
curl localhost:9998/stats          # CPU/memory/disk
curl localhost:9997/health         # Container health
curl localhost:9999/cpu            # Host CPU

# n8n API
curl -H "X-N8N-API-KEY: $KEY" localhost:8567/api/v1/workflows
```

---

*This inventory reflects the state as of 2026-02-01. Update as system evolves.*
