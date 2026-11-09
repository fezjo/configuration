#!/bin/sh
# Temporarily switch niri's Mod key to Alt for a Sunshine/Moonlight session.
# Run with "on" before the stream and "off" after it.
set -eu

CFG="${NIRI_CONFIG:-$HOME/.config/niri/config.kdl}"
RUID=$(id -u)

case "${1:-}" in
    on)
        if ! grep -q 'mod-key "Alt"' "$CFG"; then
            sed -i '/^input {/a\    mod-key "Alt"' "$CFG"
        fi
        ;;
    off)
        sed -i '/^[[:space:]]*mod-key[[:space:]]*"Alt"[[:space:]]*$/d' "$CFG"
        ;;
    *)
        echo "usage: $0 on|off" >&2
        exit 2
        ;;
esac

SOCK=$(ls /run/user/"$RUID"/niri.wayland-*.sock 2>/dev/null | head -1 || true)
if [ -n "$SOCK" ]; then
    XDG_RUNTIME_DIR=/run/user/"$RUID" NIRI_SOCKET="$SOCK" \
        niri msg action load-config-file >/dev/null 2>&1 || true
fi
