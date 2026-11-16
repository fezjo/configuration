#!/bin/sh
# Single environment source for login shells and TTY/SSH sessions.
# The graphical session gets the same values from ~/.config/environment.d.

set -a
for f in "$HOME"/.config/environment.d/*.conf; do
    [ -r "$f" ] || continue
    . "$f"
done
set +a

# GPG needs the terminal for pinentry. This file is sourced by every POSIX
# shell, so TTY and SSH sessions get the value; environment.d cannot set it
# because the tty is per shell, not per graphical session.
if [ -t 0 ]; then
    GPG_TTY=$(tty)
    export GPG_TTY
fi

# Keep a usable PATH even if environment.d is missing.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) PATH="$HOME/.local/bin:$PATH"; export PATH ;;
esac
