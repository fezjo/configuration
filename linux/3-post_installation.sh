#!/bin/bash

#CONFIG=/home/fezjo/src/configuration/linux/
CONFIG=$(pwd)

echo "Apply chezmoi from '$CONFIG/chezmoi' to '$HOME' ?"
read -p "Press enter to continue"
chezmoi apply -S $CONFIG/chezmoi

chsh

fuck
fuck

mise use -g usage
mise use -g node

# Default applications
xdg-mime default ssh.desktop x-scheme-handler/ssh

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
pypy3 -m ensurepip
pypy3 -m pip install matplotlib
pipx install input-tool shell-gpt xxh-xxh
# good tools: pre-commit pur vermin

# SSH
sudo systemctl enable --now sshd

# DNS
sudo systemctl enable --now systemd-resolved
sudo ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

# Time
sudo systemctl enable --now systemd-timesyncd

# OOM
sudo systemctl enable --now systemd-oomd

# Docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

# Distrobox
(
repo=yay-bin
setup="
sudo pacman -S --needed --noconfirm git base-devel &&
([ -d $repo ] &&
  (cd $repo && pwd && git pull) ||
  git clone https://aur.archlinux.org/yay-bin.git $repo
) &&
cd $repo &&
makepkg -si --noconfirm &&
yay -S --noconfirm fastfetch &&
echo success
"
boxname=arch-test
mkdir -p distrobox &&
cd distrobox &&
distrobox enter $boxname -- sh -c "$setup";
)

cat <<EOF
check that pacman-mirrors are ok
setup locales
pipx completions

modify /etc/pacman.conf
modify /etc/makepkg.conf
modify /etc/security/faillock.conf
modify /etc/systemd/logind.conf.d/powerbutton.conf
add things to /etc/dracut.conf.d/

setup timeshift
EOF
