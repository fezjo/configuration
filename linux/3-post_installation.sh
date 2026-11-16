#!/bin/bash
set -euo pipefail

. "$(dirname -- "$0")/system/lib.sh"

DRY_RUN=0
HOST="${CONFIG_HOST:-$(short_hostname)}"
FORM=""
CPU=""

usage() {
    cat <<'EOF'
usage: 3-post_installation.sh [--dry-run] [--host NAME]
                              [--form laptop|desktop] [--cpu amd|intel]

  -n, --dry-run   show what would change without touching the system
  --host NAME     host profile
  --form, --cpu   override hardware detection
EOF
}

CLI_USAGE=usage
parse_args "$@"

export CONFIG_HOST="$HOST"
[[ -n "$FORM" ]] && export CONFIG_FORM="$FORM"
[[ -n "$CPU" ]] && export CONFIG_CPU="$CPU"

declare -A PREDICTED_ENABLED=()
declare -A PREDICTED_ACTIVE=()

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

    local scope=system
    if (( user )); then
        scope=user
    fi
    local unit key enabled active changes
    for unit in "${units[@]}"; do
        key="$scope:$unit"
        if [[ -v "PREDICTED_ENABLED[$key]" ]]; then
            enabled=${PREDICTED_ENABLED["$key"]}
            active=${PREDICTED_ACTIVE["$key"]}
        else
            if (( user )); then
                enabled=$(systemctl --user is-enabled "$unit" 2>/dev/null || true)
                active=$(systemctl --user is-active "$unit" 2>/dev/null || true)
            else
                enabled=$(systemctl is-enabled "$unit" 2>/dev/null || true)
                active=$(systemctl is-active "$unit" 2>/dev/null || true)
            fi
            enabled=${enabled:-unknown}
            active=${active:-unknown}
            PREDICTED_ENABLED["$key"]=$enabled
            PREDICTED_ACTIVE["$key"]=$active
        fi

        if [[ $enabled == not-found ]]; then
            printf '    [dry-run] %s: unit not found -> real run would fail\n' "$unit"
            continue
        fi

        changes=()
        case "$action" in
            enable)
                [[ $enabled == enabled ]] || changes+=("enable")
                if (( now )); then
                    [[ $active == active ]] || changes+=("start")
                fi
                PREDICTED_ENABLED["$key"]=enabled
                if (( now )); then
                    PREDICTED_ACTIVE["$key"]=active
                fi
                ;;
            disable)
                [[ $enabled == disabled ]] || changes+=("disable")
                if (( now )); then
                    [[ $active == inactive ]] || changes+=("stop")
                fi
                PREDICTED_ENABLED["$key"]=disabled
                if (( now )); then
                    PREDICTED_ACTIVE["$key"]=inactive
                fi
                ;;
            start)
                [[ $active == active ]] || changes+=("start")
                PREDICTED_ACTIVE["$key"]=active
                ;;
            stop)
                [[ $active == inactive ]] || changes+=("stop")
                PREDICTED_ACTIVE["$key"]=inactive
                ;;
            restart)
                changes+=("restart")
                PREDICTED_ACTIVE["$key"]=active
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
USER_NAME="${USER:-$(id -un)}"
# $SHELL reflects the shell that started this script, not the login shell, and
# stays stale after chsh. Read the authoritative value from the passwd entry.
LOGIN_SHELL="$(getent passwd "$USER_NAME" 2>/dev/null | cut -d: -f7 || true)"
LOGIN_SHELL="${LOGIN_SHELL:-${SHELL:-}}"

if command -v python3 >/dev/null 2>&1; then
    host_args=(python3 "$CONFIG/system/hostinfo.py" --host "$HOST")
    [[ -n "$FORM" ]] && host_args+=(--form "$FORM")
    [[ -n "$CPU" ]] && host_args+=(--cpu "$CPU")
    host_args+=(shell-env)
    host_env=$("${host_args[@]}") || {
        echo "error: cannot resolve host profile '$HOST'" >&2
        exit 1
    }
    eval "$host_env"
    export CONFIG_HOST CONFIG_FORM CONFIG_CPU CONFIG_COMPOSITOR CONFIG_SHELL
    export CONFIG_ROLES
else
    warn "python3 is missing; host-specific hooks are disabled"
    CONFIG_FORM="${FORM:-desktop}"
    CONFIG_CPU="${CPU:-amd}"
    CONFIG_COMPOSITOR=""
    CONFIG_SHELL=""
    CONFIG_ROLES=""
fi

HAVE_SSH_KEY=0
if [ -f "$HOME/.ssh/ssh_fezjo" ]; then
    HAVE_SSH_KEY=1
elif (( DRY_RUN )); then
    warn "missing SSH identity: $HOME/.ssh/ssh_fezjo; skipping chezmoi preview (the real run would abort)"
else
    echo "missing SSH identity: $HOME/.ssh/ssh_fezjo" >&2
    exit 1
fi

# DMS owns its colors/alttab/cursor fragments, not the keymap or output layout.
# Deploy defaults only when a fragment is missing so theme updates survive.
if [[ "$CONFIG_SHELL" == dms ]] && command -v dms >/dev/null 2>&1; then
    for fragment in colors alttab cursor; do
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

if (( HAVE_SSH_KEY )); then
    chezmoi --config "$CHEZMOI_CONFIG" apply -n -S "$CONFIG/chezmoi" \
        || warn "chezmoi preview failed"
fi

if (( DRY_RUN )); then
    if (( HAVE_SSH_KEY )); then
        printf '    [dry-run] chezmoi apply -S %s\n' "$CONFIG/chezmoi"
    fi
else
    echo "Apply chezmoi from '$CONFIG/chezmoi' to '$HOME' ?"
    if ! read -r -p "Apply? [Y/n] " reply; then
        echo "aborted (no input)" >&2
        exit 1
    fi
    case "${reply,,}" in
        ""|y|yes) ;;
        n|no) echo "aborted" >&2; exit 1 ;;
        *) echo "please answer y or n" >&2; exit 1 ;;
    esac
    chezmoi --config "$CHEZMOI_CONFIG" apply -S "$CONFIG/chezmoi"
fi

FISH_SHELL="$(command -v fish 2>/dev/null || true)"
if [[ -n "$FISH_SHELL" ]]; then
    if [[ "$LOGIN_SHELL" == "$FISH_SHELL" ]]; then
        (( DRY_RUN )) && printf '    [dry-run] chsh: login shell is %s -> no change\n' "$LOGIN_SHELL"
    else
        run chsh -s "$FISH_SHELL" || warn "could not change shell"
    fi
fi

run mise use -g usage || warn "mise usage setup failed"
run mise use -g node || warn "mise node setup failed"

# Memory: zram + swapfile overflow + systemd-oomd
if (( DRY_RUN )); then
    bash "$CONFIG/system/memory.sh" --dry-run
else
    sudo bash "$CONFIG/system/memory.sh" --yes
fi

# Tailscale
run_systemctl enable --now tailscaled || warn "tailscaled setup failed"
run sudo tailscale up || warn "tailscale up failed"
run sudo tailscale set --ssh || warn "tailscale ssh setup failed"

# Bluetooth
run_systemctl enable --now bluetooth.service || warn "bluetooth setup failed"

# Keyboard, sudoers, logind, and SysRq settings are installed by
# linux/system/apply.py before this script runs. OOM/sysctl tuning is
# handled by system/memory.sh.

# Camera
run sudo usermod -aG video "$USER_NAME" || warn "video group setup failed"

# Python
run pipx ensurepath || warn "pipx ensurepath failed"
run pypy3 -m ensurepip || warn "pypy ensurepip failed"
# PyPy has no matplotlib wheel; keep the source build best-effort and out of
# the main log.
if (( DRY_RUN )); then
    printf '    [dry-run] pypy3 -m pip install matplotlib\n'
elif ! pypy3 -m pip install matplotlib >/tmp/pypy-matplotlib.log 2>&1; then
    warn "pypy matplotlib install failed; see /tmp/pypy-matplotlib.log"
fi
for tool in input-tool shell-gpt xxh-xxh; do
    run uv tool install "$tool" || warn "uv tool install $tool failed"
done
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
# configured by system/memory.sh and activated below.

# Docker / libvirt groups
run_systemctl enable --now docker || warn "docker setup failed"
for group in docker libvirt; do
    if getent group "$group" >/dev/null 2>&1; then
        run sudo usermod -aG "$group" "$USER_NAME" || warn "could not add $USER_NAME to $group"
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
run_systemctl enable greetd || warn "greetd setup failed"

# Switch away from a legacy display manager without killing the running session.
if systemctl cat lightdm.service >/dev/null 2>&1; then
    run_systemctl disable lightdm || warn "could not disable lightdm"
    warn "lightdm disabled; reboot to start greetd"
fi

run_systemctl enable --now systemd-oomd.socket systemd-oomd.service
run_systemctl restart systemd-oomd.service

# Timeshift
if (( DRY_RUN )); then
    bash "$CONFIG/system/timeshift.sh" --dry-run
else
    sudo bash "$CONFIG/system/timeshift.sh" --yes
fi

run_hook() {
    local hook=$1
    [[ -f "$hook" ]] || return 0
    if (( DRY_RUN )); then
        printf '    [dry-run] bash %s\n' "$hook"
    else
        bash "$hook"
    fi
}

run_hook "$CONFIG/hooks/form/$CONFIG_FORM.sh"
run_hook "$CONFIG/hooks/compositor/$CONFIG_COMPOSITOR.sh"
run_hook "$CONFIG/hooks/shell/$CONFIG_SHELL.sh"
for role in $CONFIG_ROLES; do
    run_hook "$CONFIG/hooks/role/$role.sh"
done

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
EOF
fi
