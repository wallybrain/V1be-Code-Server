#!/bin/sh
# Allow Docker containers on the webproxy bridge to reach host services
# Required because Hostinger's firewall blocks container-to-host INPUT traffic
#
# Also DROP external (eth0) access to internal-only ports:
#   8080  - code-server (should only be reached via Caddy+Authelia)
#   11434 - Ollama (should only be reached via Caddy with bearer auth)
#   9999  - CPU monitor (internal only)
docker run --rm --privileged --net=host ubuntu:24.04 bash -c \
  "apt-get update -qq && apt-get install -y -qq iptables > /dev/null 2>&1 && \
   \
   # ACCEPT: Docker bridge -> host services
   iptables -C INPUT -i br-03b170a2a124 -p tcp --dport 8080 -j ACCEPT 2>/dev/null || \
   iptables -I INPUT -i br-03b170a2a124 -p tcp --dport 8080 -j ACCEPT && \
   echo 'ACCEPT bridge -> port 8080 (code-server)' && \
   \
   iptables -C INPUT -i br-03b170a2a124 -p tcp --dport 11434 -j ACCEPT 2>/dev/null || \
   iptables -I INPUT -i br-03b170a2a124 -p tcp --dport 11434 -j ACCEPT && \
   echo 'ACCEPT bridge -> port 11434 (ollama)' && \
   \
   # DROP: Block external access to internal-only ports
   iptables -C INPUT -i eth0 -p tcp --dport 8080 -j DROP 2>/dev/null || \
   iptables -A INPUT -i eth0 -p tcp --dport 8080 -j DROP && \
   echo 'DROP eth0 -> port 8080 (code-server)' && \
   \
   iptables -C INPUT -i eth0 -p tcp --dport 11434 -j DROP 2>/dev/null || \
   iptables -A INPUT -i eth0 -p tcp --dport 11434 -j DROP && \
   echo 'DROP eth0 -> port 11434 (ollama)' && \
   \
   iptables -C INPUT -i eth0 -p tcp --dport 9999 -j DROP 2>/dev/null || \
   iptables -A INPUT -i eth0 -p tcp --dport 9999 -j DROP && \
   echo 'DROP eth0 -> port 9999 (cpu-monitor)'"
