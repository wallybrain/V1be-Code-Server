#!/bin/bash
# Automated security scanning with Lynis and rkhunter
# Run manually: sudo bash /home/lwb3/v1be-code-server/security-scan.sh
# Or via cron/systemd timer (see security-scan.timer)
#
# What it does:
#   1. Runs rkhunter rootkit check
#   2. Runs Lynis system audit
#   3. Logs results to /var/log/security-scan/
#   4. Sends Discord webhook on score regression or rkhunter warnings
#
# After apt upgrade, run with --update-baseline to refresh rkhunter's file hashes

set -euo pipefail

LOG_DIR="/var/log/security-scan"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
RKHUNTER_LOG="$LOG_DIR/rkhunter-$TIMESTAMP.log"
LYNIS_LOG="$LOG_DIR/lynis-$TIMESTAMP.log"
SCORE_FILE="$LOG_DIR/last-lynis-score"
DISCORD_WEBHOOK="${DISCORD_SECURITY_WEBHOOK:-}"

mkdir -p "$LOG_DIR"

log() { echo "[$(date '+%H:%M:%S')] $1"; }

send_discord() {
    local message="$1"
    if [ -n "$DISCORD_WEBHOOK" ]; then
        curl -s -H "Content-Type: application/json" \
            -d "{\"content\": \"$message\"}" \
            "$DISCORD_WEBHOOK" > /dev/null 2>&1 || true
    fi
}

# ─────────────────────────────────────────────
# Handle --update-baseline flag (run after apt upgrade)
# ─────────────────────────────────────────────
if [ "${1:-}" = "--update-baseline" ]; then
    log "Updating rkhunter file property baseline..."
    rkhunter --propupd
    log "Baseline updated. Run a normal scan next."
    exit 0
fi

# ─────────────────────────────────────────────
# 1. rkhunter — rootkit and binary integrity check
# ─────────────────────────────────────────────
log "Starting rkhunter scan..."
rkhunter --check --skip-keypress --report-warnings-only > "$RKHUNTER_LOG" 2>&1 || true

RKHUNTER_WARNINGS=$(grep -c "Warning:" "$RKHUNTER_LOG" 2>/dev/null || echo "0")
log "rkhunter complete — $RKHUNTER_WARNINGS warning(s)"

if [ "$RKHUNTER_WARNINGS" -gt 0 ]; then
    log "WARNING: rkhunter found issues — review $RKHUNTER_LOG"
    send_discord "⚠️ **Security Scan**: rkhunter found $RKHUNTER_WARNINGS warning(s). Review \`$RKHUNTER_LOG\`"
fi

# ─────────────────────────────────────────────
# 2. Lynis — system hardening audit
# ─────────────────────────────────────────────
log "Starting Lynis audit..."
lynis audit system --no-colors --quiet > "$LYNIS_LOG" 2>&1 || true

# Extract hardening index from Lynis report
LYNIS_REPORT="/var/log/lynis-report.dat"
CURRENT_SCORE=$(grep "hardening_index=" "$LYNIS_REPORT" 2>/dev/null | cut -d= -f2 || echo "unknown")
log "Lynis complete — hardening index: $CURRENT_SCORE"

# Compare with previous score
PREVIOUS_SCORE=$(cat "$SCORE_FILE" 2>/dev/null || echo "0")
echo "$CURRENT_SCORE" > "$SCORE_FILE"

if [ "$CURRENT_SCORE" != "unknown" ] && [ "$PREVIOUS_SCORE" != "0" ]; then
    if [ "$CURRENT_SCORE" -lt "$PREVIOUS_SCORE" ] 2>/dev/null; then
        log "REGRESSION: Lynis score dropped from $PREVIOUS_SCORE to $CURRENT_SCORE"
        send_discord "📉 **Security Scan**: Lynis hardening index dropped from $PREVIOUS_SCORE → $CURRENT_SCORE. Review \`$LYNIS_LOG\`"
    fi
fi

# ─────────────────────────────────────────────
# 3. Cleanup old logs (keep 90 days)
# ─────────────────────────────────────────────
find "$LOG_DIR" -name "*.log" -mtime +90 -delete 2>/dev/null || true

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
log "─────────────────────────────────"
log "Security scan complete"
log "  rkhunter: $RKHUNTER_WARNINGS warning(s)"
log "  Lynis:    $CURRENT_SCORE/100"
log "  Logs:     $LOG_DIR/"
log "─────────────────────────────────"
