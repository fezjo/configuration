#!/usr/bin/env bash
# DMS-specific post-install hook.
set -euo pipefail

if command -v dms >/dev/null 2>&1; then
    systemctl --user daemon-reload || true
fi
