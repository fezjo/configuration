#!/bin/sh
# Switch niri's Mod key to Alt while a Sunshine stream is active, and back
# to Super when the last client disconnects.  Sunshine's prep-cmd "do" runs
# reliably, but its "undo" is not run on client disconnect.
LOG="${SUNSHINE_LOG:-$HOME/.config/sunshine/sunshine.log}"
MOD_ALT="$HOME/.local/bin/niri-mod-alt.sh"

while [ ! -f "$LOG" ]; do
    sleep 1
done

tail -n0 -F "$LOG" 2>/dev/null | while IFS= read -r line; do
    case "$line" in
        *"CLIENT CONNECTED"*)
            "$MOD_ALT" on >/dev/null 2>&1 || true
            ;;
        *"CLIENT DISCONNECTED"*|*"Session ended"*)
            "$MOD_ALT" off >/dev/null 2>&1 || true
            ;;
    esac
done
