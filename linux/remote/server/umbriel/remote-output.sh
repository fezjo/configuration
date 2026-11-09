#!/bin/sh
set -eu
name=remote
mode=${UMBRIEL_REMOTE_MODE:-1920x1080@60}
/usr/bin/umbriel output-destroy "$name" >/dev/null 2>&1 || true
/usr/bin/umbriel output-create "$name" "$mode"
