# Fix Continue.dev + Ollama Integration

## Problem
Continue.dev in code-server (browser) can't reach `localhost:11434` because Ollama only listens locally. Browser requests go to the wrong localhost.

## Solution
Expose Ollama through Caddy as a secure endpoint.

## Steps

### 1. Edit Caddyfile
Add this block to `/home/lwb3/v1be-code-server/Caddyfile`:

```
ollama.example.com {
    reverse_proxy host.docker.internal:11434

    # Optional: Add auth if you want (using same Authelia)
    forward_auth authelia:9091 {
        uri /api/verify?rd=https://auth.example.com
        copy_headers Remote-User Remote-Groups Remote-Name Remote-Email
    }
}
```

### 2. Add DNS Record
In your domain registrar, add:
- **Type**: A
- **Name**: `ollama`
- **Value**: `YOUR_SERVER_IP`

### 3. Update Continue Config
Edit `~/.continue/config.json` and change all `apiBase` entries from:
```json
"apiBase": "http://localhost:11434"
```
To:
```json
"apiBase": "https://ollama.example.com"
```

### 4. Restart Caddy
```bash
cd /home/lwb3/v1be-code-server
docker compose restart caddy
```

### 5. Test
```bash
# From your local machine or anywhere:
curl https://ollama.example.com/api/tags
```

Should return JSON list of models.

## Alternative: Run Continue Locally Instead

If you don't want to expose Ollama publicly, you could:
1. Use VS Code desktop app on your local machine
2. SSH tunnel to access Ollama: `ssh -L 11434:localhost:11434 user@example.com`
3. Install Continue.dev locally and use `http://localhost:11434`

This way everything stays local, but you lose the browser-based convenience.

## Security Note
The auth block in the Caddyfile is commented as optional. If you include it, users need to authenticate via Authelia before accessing Ollama. If you omit it, anyone with the URL can use your models (consider rate limiting or keeping it without auth if only you know the URL).
