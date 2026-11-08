#!/bin/sh
# Single environment source for login shells and TTY/SSH sessions.
# The graphical session gets the same values from ~/.config/environment.d.

set -a
for f in "$HOME"/.config/environment.d/*.conf; do
    [ -r "$f" ] || continue
    . "$f"
done
set +a

# Keep a usable PATH even if environment.d is missing.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac
