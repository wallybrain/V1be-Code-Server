#!/bin/sh
# Source custom aliases and shell config from the persistent workspace mount
ALIASES="/home/coder/workspace/.code-server-ssh/aliases.sh"
BASHRC="/root/.bashrc"

if [ -f "$ALIASES" ]; then
  grep -q "code-server-ssh/aliases" "$BASHRC" 2>/dev/null || \
    echo "source $ALIASES" >> "$BASHRC"
fi
