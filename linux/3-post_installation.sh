#!/bin/bash
set -euo pipefail

CONFIG="$(cd -- "$(dirname -- "$0")" && pwd)"
CHEZMOI_CONFIG="$CONFIG/chezmoi/dot_config/chezmoi/chezmoi.toml"

warn() { printf '    warn: %s\n' "$*" >&2; }

if [ ! -f "$HOME/.config/age/keys.txt" ]; then
    echo "missing age identity: $HOME/.config/age/keys.txt" >&2
    exit 1
fi

chezmoi --config "$CHEZMOI_CONFIG" apply -n -S "$CONFIG/chezmoi"
echo "Apply chezmoi from '$CONFIG/chezmoi' to '$HOME' ?"
read -p "Press enter to continue"
chezmoi --config "$CHEZMOI_CONFIG" apply -S "$CONFIG/chezmoi"


if [[ "$SHELL" != */fish ]]; then
    if command -v fish >/dev/null 2>&1; then
        chsh -s "$(command -v fish)" || warn "could not change shell"
    fi
fi

mise use -g usage || warn "mise usage setup failed"
mise use -g node || warn "mise node setup failed"

# Memory: zram + swapfile overflow + systemd-oomd
# (run by setup.sh as step 4; safe to re-run any time)
# sudo bash "$CONFIG/4-memory.sh" --yes

# Tailscale
sudo systemctl enable --now tailscaled || warn "tailscaled setup failed"
sudo tailscale up || warn "tailscale up failed"
sudo tailscale set --ssh || warn "tailscale ssh setup failed"

# Bluetooth
sudo systemctl enable --now bluetooth.service || warn "bluetooth setup failed"

# Keyboard, sudoers, logind, SysRq and OOM drop-ins
# are installed by linux/system/apply.py before this script runs.

# Camera
sudo usermod -aG video "$USER" || warn "video group setup failed"

# Python
pipx ensurepath || warn "pipx ensurepath failed"
pypy3 -m ensurepip || warn "pypy ensurepip failed"
pypy3 -m pip install matplotlib || warn "pypy matplotlib install failed"
uv tool install input-tool shell-gpt xxh-xxh || warn "uv tool install failed"
# good tools: pre-commit pur vermin

# Cron
sudo systemctl enable --now cronie || warn "cronie setup failed"

# SSH agent socket
systemctl --user enable --now ssh-agent.socket || warn "ssh-agent socket setup failed"

# SSH
sudo systemctl enable --now sshd || warn "sshd setup failed"

# DNS
sudo systemctl enable --now systemd-resolved || warn "systemd-resolved setup failed"
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Time
sudo systemctl enable --now systemd-timesyncd || warn "systemd-timesyncd setup failed"

# OOM
# configured by 4-memory.sh and activated below.

# Docker / libvirt groups
sudo systemctl enable --now docker || warn "docker setup failed"
for group in docker libvirt; do
    if getent group "$group" >/dev/null 2>&1; then
        sudo usermod -aG "$group" "$USER" || warn "could not add $USER to $group"
    fi
done

# System activation after system/apply.py
sudo visudo -c
sudo pacman-conf --config /etc/pacman.conf >/dev/null
sudo systemctl daemon-reload
sudo sysctl --system
sudo localectl set-x11-keymap us-sk_dia
sudo systemctl enable --now keyd
sudo systemctl restart keyd
sudo systemctl enable greetd
sudo systemctl enable --now systemd-oomd.socket systemd-oomd.service
sudo systemctl restart systemd-oomd.service

# Distrobox test box: create it explicitly with `db new arch-test` when needed.

# My projects
mkdir -p "$HOME/src" || warn "could not create ~/src"
if [ ! -d "$HOME/src/basrs/.git" ]; then
    git clone https://github.com/fezjo/basrs.git "$HOME/src/basrs" || warn "basrs clone failed"
fi
if [ -d "$HOME/src/basrs/.git" ]; then
    ( cd "$HOME/src/basrs" && cargo install --path . ) || warn "basrs install failed"
fi

cat <<EOF
check that pacman-mirrors are ok
setup locales
pipx completions

system files are applied by system/apply.py
setup timeshift
EOF
