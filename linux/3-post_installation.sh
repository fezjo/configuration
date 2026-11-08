#!/bin/bash
set -euo pipefail

DRY_RUN=0

usage() {
    cat <<'EOF'
usage: 3-post_installation.sh [--dry-run]

  -n, --dry-run   show what would change without touching the system
EOF
}

while (( $# )); do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

run() {
    if (( DRY_RUN )); then
        printf '    [dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

CONFIG="$(cd -- "$(dirname -- "$0")" && pwd)"
CHEZMOI_CONFIG="$CONFIG/chezmoi/dot_config/chezmoi/chezmoi.toml"

warn() { printf '    warn: %s\n' "$*" >&2; }

if [ ! -f "$HOME/.ssh/ssh_fezjo" ]; then
    if (( DRY_RUN )); then
        warn "missing SSH identity: $HOME/.ssh/ssh_fezjo; skipping chezmoi preview"
    else
        echo "missing SSH identity: $HOME/.ssh/ssh_fezjo" >&2
        exit 1
    fi
fi

# DMS owns its colors/alttab/outputs/cursor fragments, not the keymap.
# Deploy defaults only when a fragment is missing so theme updates survive.
if command -v dms >/dev/null 2>&1; then
    for fragment in colors alttab outputs cursor; do
        if [ ! -f "$HOME/.config/niri/dms/$fragment.kdl" ]; then
            if (( DRY_RUN )); then
                printf '    [dry-run] dms setup %s\n' "$fragment"
            else
                dms setup "$fragment" </dev/null >/dev/null 2>&1 \
                    || warn "dms setup $fragment failed"
            fi
        fi
    done
fi

if [ -f "$HOME/.ssh/ssh_fezjo" ]; then
    chezmoi --config "$CHEZMOI_CONFIG" apply -n -S "$CONFIG/chezmoi" \
        || warn "chezmoi preview failed"
fi

if (( DRY_RUN )); then
    printf '    [dry-run] chezmoi apply -S %s\n' "$CONFIG/chezmoi"
else
    echo "Apply chezmoi from '$CONFIG/chezmoi' to '$HOME' ?"
    read -p "Press enter to continue"
    chezmoi --config "$CHEZMOI_CONFIG" apply -S "$CONFIG/chezmoi"
fi

if [[ "$SHELL" != */fish ]]; then
    if command -v fish >/dev/null 2>&1; then
        run chsh -s "$(command -v fish)" || warn "could not change shell"
    fi
fi

run mise use -g usage || warn "mise usage setup failed"
run mise use -g node || warn "mise node setup failed"

# Memory: zram + swapfile overflow + systemd-oomd
# (run by setup.sh as step 4; safe to re-run any time)
# sudo bash "$CONFIG/4-memory.sh" --yes

# Tailscale
run sudo systemctl enable --now tailscaled || warn "tailscaled setup failed"
run sudo tailscale up || warn "tailscale up failed"
run sudo tailscale set --ssh || warn "tailscale ssh setup failed"

# Bluetooth
run sudo systemctl enable --now bluetooth.service || warn "bluetooth setup failed"

# Keyboard, sudoers, logind, SysRq and OOM drop-ins
# are installed by linux/system/apply.py before this script runs.

# Camera
run sudo usermod -aG video "$USER" || warn "video group setup failed"

# Python
run pipx ensurepath || warn "pipx ensurepath failed"
run pypy3 -m ensurepip || warn "pypy ensurepip failed"
run pypy3 -m pip install matplotlib || warn "pypy matplotlib install failed"
run uv tool install input-tool shell-gpt xxh-xxh || warn "uv tool install failed"
# good tools: pre-commit pur vermin

# Cron
run sudo systemctl enable --now cronie || warn "cronie setup failed"

# SSH agent socket
run systemctl --user enable --now ssh-agent.socket || warn "ssh-agent socket setup failed"

# SSH
run sudo systemctl enable --now sshd || warn "sshd setup failed"

# DNS
run sudo systemctl enable --now systemd-resolved || warn "systemd-resolved setup failed"
run sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Time
run sudo systemctl enable --now systemd-timesyncd || warn "systemd-timesyncd setup failed"

# OOM
# configured by 4-memory.sh and activated below.

# Docker / libvirt groups
run sudo systemctl enable --now docker || warn "docker setup failed"
for group in docker libvirt; do
    if getent group "$group" >/dev/null 2>&1; then
        run sudo usermod -aG "$group" "$USER" || warn "could not add $USER to $group"
    fi
done

# System activation after system/apply.py
run sudo visudo -c
if (( DRY_RUN )); then
    printf '    [dry-run] sudo pacman-conf --config /etc/pacman.conf\n'
else
    sudo pacman-conf --config /etc/pacman.conf >/dev/null
fi
run sudo systemctl daemon-reload
run sudo sysctl --system
run sudo localectl set-x11-keymap us-sk_dia
run sudo systemctl enable --now keyd
run sudo systemctl restart keyd
run sudo systemctl enable greetd
run sudo systemctl enable --now systemd-oomd.socket systemd-oomd.service
run sudo systemctl restart systemd-oomd.service

# Distrobox test box: create it explicitly with `db new arch-test` when needed.

# My projects
run mkdir -p "$HOME/src" || warn "could not create ~/src"
if (( DRY_RUN )); then
    printf '    [dry-run] git clone https://github.com/fezjo/basrs.git %s\n' "$HOME/src/basrs"
    printf '    [dry-run] (cd %s && cargo install --path .)\n' "$HOME/src/basrs"
else
    if [ ! -d "$HOME/src/basrs/.git" ]; then
        git clone https://github.com/fezjo/basrs.git "$HOME/src/basrs" || warn "basrs clone failed"
    fi
    if [ -d "$HOME/src/basrs/.git" ]; then
        ( cd "$HOME/src/basrs" && cargo install --path . ) || warn "basrs install failed"
    fi
fi

if (( DRY_RUN )); then
    echo
    echo "Dry run complete. No changes were made."
else
    cat <<EOF
check that pacman-mirrors are ok
setup locales
pipx completions

system files are applied by system/apply.py
setup timeshift
EOF
fi
