#!/usr/bin/env bash
# Open the Sunshine ports in firewalld on the server.
# Run with sudo.
set -euo pipefail

if ! command -v firewall-cmd >/dev/null 2>&1; then
    echo "firewall-cmd not found; open these ports in your firewall instead:" >&2
    echo "  TCP 47984-47990, 48010" >&2
    echo "  UDP 47998-48002, 48010" >&2
    exit 1
fi

firewall-cmd --permanent --add-port=47984-47990/tcp
firewall-cmd --permanent --add-port=48010/tcp
firewall-cmd --permanent --add-port=47998-48002/udp
firewall-cmd --permanent --add-port=48010/udp
firewall-cmd --reload

echo "Sunshine ports:"
firewall-cmd --list-ports
