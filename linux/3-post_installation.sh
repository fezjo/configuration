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

run_systemctl() {
    local -a args=("$@")
    local user=0
    if [[ ${args[0]:-} == --user ]]; then
        user=1
        args=("${args[@]:1}")
    fi

    if (( ! DRY_RUN )); then
        if (( user )); then
            systemctl --user "${args[@]}"
        else
            sudo systemctl "${args[@]}"
        fi
        return
    fi

    local action=${args[0]:-}
    local now=0
    local -a units=()
    local arg
    for arg in "${args[@]:1}"; do
        case "$arg" in
            --now) now=1 ;;
            -*) ;;
            *) units+=("$arg") ;;
        esac
    done

    if (( ${#units[@]} == 0 )); then
        printf '    [dry-run] systemctl %s\n' "${args[*]}"
        return
    fi

    local unit enabled active changes
    for unit in "${units[@]}"; do
        if (( user )); then
            enabled=$(systemctl --user is-enabled "$unit" 2>/dev/null || true)
            active=$(systemctl --user is-active "$unit" 2>/dev/null || true)
        else
            enabled=$(systemctl is-enabled "$unit" 2>/dev/null || true)
            active=$(systemctl is-active "$unit" 2>/dev/null || true)
        fi
        enabled=${enabled:-unknown}
        active=${active:-unknown}
        changes=()

        case "$action" in
            enable)
                [[ $enabled == enabled ]] || changes+=("enable")
                if (( now )); then
                    [[ $active == active ]] || changes+=("start")
                fi
                ;;
            disable)
                [[ $enabled == disabled ]] || changes+=("disable")
                ;;
            start)
                [[ $active == active ]] || changes+=("start")
                ;;
            stop)
                [[ $active == inactive ]] || changes+=("stop")
                ;;
            restart)
                changes+=("restart")
                ;;
            *)
                changes+=("$action")
                ;;
        esac

        if (( ${#changes[@]} == 0 )); then
            printf '    [dry-run] %s: %s, %s -> no change\n' "$unit" "$enabled" "$active"
        else
            printf '    [dry-run] %s: %s, %s -> %s\n' "$unit" "$enabled" "$active" "${changes[*]}"
        fi
    done
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
run_systemctl enable --now tailscaled || warn "tailscaled setup failed"
run sudo tailscale up || warn "tailscale up failed"
run sudo tailscale set --ssh || warn "tailscale ssh setup failed"

# Bluetooth
run_systemctl enable --now bluetooth.service || warn "bluetooth setup failed"

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
run_systemctl enable --now cronie || warn "cronie setup failed"

# SSH agent socket
run_systemctl --user enable --now ssh-agent.socket || warn "ssh-agent socket setup failed"

# SSH
run_systemctl enable --now sshd || warn "sshd setup failed"

# DNS
run_systemctl enable --now systemd-resolved || warn "systemd-resolved setup failed"
run sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Time
run_systemctl enable --now systemd-timesyncd || warn "systemd-timesyncd setup failed"

# OOM
# configured by 4-memory.sh and activated below.

# Docker / libvirt groups
run_systemctl enable --now docker || warn "docker setup failed"
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
run_systemctl enable --now keyd
run_systemctl restart keyd
run_systemctl enable greetd
run_systemctl enable --now systemd-oomd.socket systemd-oomd.service
run_systemctl restart systemd-oomd.service

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
