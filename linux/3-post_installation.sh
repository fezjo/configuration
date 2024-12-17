#!/bin/bash

#CONFIG=/home/fezjo/src/configuration/linux/
CONFIG=.

chezmoi apply -S $CONFIG/chezmoi

chsh

fuck
fuck

mise use -g usage

# ZSwap
sudo btrfs subvolume create /swap
btrfs filesystem mkswapfile --size 16g --uuid clear /swap/swapfile
sudo swapon /swap/swapfile
echo "/swap/swapfile none swap defaults 0 0" | sudo tee -a /etc/fstab
echo " zswap.enabled=1 zswap.compressor=lz4 zswap.max_pool_percent=35" | sudo tee -a /etc/kernel/cmdline
sudo reinstall-kernels

# Tailscale
sudo systemctl enable --now tailscaled
sudo tailscale up
sudo tailscale set --ssh

# Bluetooth
sudo systemctl enable --now bluetooth.service

# Keyboard
sudo cp $CONFIG/root/usr/share/X11/xkb/symbols/* /usr/share/X11/xkb/symbols/
sudo cp $CONFIG/root/etc/keyd/default.conf /etc/keyd/
sudo systemctl enable --now keyd
sudo systemctl restarat keyd
localectl set-x11-keymap us-sk_dia
localectl

# Python
pipx ensurepath

# SSH
sudo systemctl enable --now sshd

# DNS
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Time
sudo systemctl enable --now systemd-timesyncd


cat <<EOF
check that pacman-mirrors are ok
setup locales
pipx completions

modify /etc/pacman.conf
modify /etc/makepkg.conf
modify /etc/security/faillock.conf
modify /etc/systemd/logind.conf.d/powerbutton.conf
add things to /etc/dracut.conf.d/
EOF
