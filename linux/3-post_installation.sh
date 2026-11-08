#!/bin/bash

CONFIG="$(cd -- "$(dirname -- "$0")" && pwd)"

chezmoi apply -nv -S $CONFIG/chezmoi
echo "Apply chezmoi from '$CONFIG/chezmoi' to '$HOME' ?"
read -p "Press enter to continue"
chezmoi apply -S $CONFIG/chezmoi

if command -v setup-universal-clipboard >/dev/null 2>&1; then
    setup-universal-clipboard || true
fi


if [[ "$SHELL" != */fish ]]; then
    if command -v fish >/dev/null 2>&1; then
        chsh -s "$(command -v fish)"
    fi
fi

mise use -g usage
mise use -g node

# Default applications
xdg-mime default ssh.desktop x-scheme-handler/ssh

# Memory: zram + swapfile overflow + systemd-oomd
# (run by setup.sh as step 4; safe to re-run any time)
# sudo bash "$CONFIG/4-memory.sh" --yes

# Tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
sudo tailscale set --ssh

# Bluetooth
sudo systemctl enable --now bluetooth.service

# Keyboard, sudoers, logind, SysRq and OOM drop-ins
# are installed by linux/system/apply.py before this script runs.

# Camera
sudo usermod -aG video $USER

# Python
pipx ensurepath
pypy3 -m ensurepip
pypy3 -m pip install matplotlib
uv tool install input-tool shell-gpt xxh-xxh
# good tools: pre-commit pur vermin

# Cron
sudo systemctl enable --now cronie

# SSH
sudo systemctl enable --now sshd

# DNS
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Time
sudo systemctl enable --now systemd-timesyncd

# OOM
# configured by 4-memory.sh and activated below.

# Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

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

# Distrobox test box: create it explicitly with `db new arch-test` when needed.

# My projects
mkdir -p "$HOME/src"
if [ ! -d "$HOME/src/basrs/.git" ]; then
    git clone https://github.com/fezjo/basrs.git "$HOME/src/basrs"
fi
(
    cd "$HOME/src/basrs"
    cargo install --path .
)

cat <<EOF
check that pacman-mirrors are ok
setup locales
pipx completions

system files are applied by system/apply.py
setup timeshift
EOF
