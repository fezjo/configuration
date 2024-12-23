# Dotfiles
TODO

# Packages

### Old
```
baobab bat base base-devel copyq feh flameshot gimp gnome-disk-utility \
gparted htop idlex libreoffice man mpv nerd-fonts-roboto-mono neovim \
oh-my-zsh-git pamixer pinta qbittorrent redshift rsync syncplay \
telegram-desktop tk tokei valgrind viewnior visual-studio-code-bin \
vivaldi wormhole-william yt-dlp zsh-theme-powerlevel10k

lxappearance-gtk3 dconf
solaar tmux discord play-with-mpv zoom slack firefox
mpd ncmpcpp
polkit gnome-keyring polkit-gnome bluez nm-applet networkmanager
sway swaylock swayi3dle wev wdisplays xorg-xwayland foot xdg-desktop-portal[,-wlr] grim slurp wl-copy kanshi wlsunset sway-systemd
dracut efibootmgr
mousepad thunar
pscircle
cf-tool time zip unzip atool
xonsh python-pip python-sympy 
man-pages wsdd
unrar
firacode noto-fonts-emoji
geary gnome-control-center
parsec-bin
linux-tools

i3-wm i3exit i3lock polybar rofi dunst alacritty

kooha geogebra? bottom cheese gnome-clocks gnome-power-statistics   
```

## System
```
base base-devel linux-tools
man man-pages
openssh netctl
dracut efibootmgr
dconf budgie-control-center gnome-control-center lxappearance-gtk3
polkit gnome-keyring polkit-gnome
seahorse
xdg-desktop-portal
```

## Basic
```
nemo kooha cheese gnome-clocks
gnome-power-statistics
wine
```

#### Daemons
```
keyd
solaar stretchly safeeyes
bluez nm-applet networkmanager
parsec-bin
flameshot redshift
```

#### Internet
```
firefox chromium qbittorrent
```

#### Media
```
feh gimp pinta viewnoir
mpv syncplay yt-dlp play-with-mpv
pamixer mpd ncmpcpp audacity
```

#### Messaging
```
discord geary telegram-desktop slack
```

### Random
```
pscircle tk
nerd-fonts-roboto-mono ttf-firacode-nerd noto-fonts-emoji ttf-ms-win11-auto
```

### Virtualization
```
qemu-desktop libvirt
quickemu virt-manager virtualbox
distrobox
```

### Configuration
```
aconfmgr
chezmoi xdg-ninja antidot-bin
```

## Desktop manager

### Wayland
```
wev wdisplays xorg-wayland
xdg-desktop-portal-wlr
grim slurp wl-copy
kanshi wlsunset
```

#### Sway
```
sway swaylock swayidle sway-systemd
```

#### i3
```bash
sudo pacman -S i3-wm i3-exit i3lock polybar

# https://github.com/endeavouros-team/endeavouros-i3wm-setup
wget https://raw.githubusercontent.com/endeavouros-team/endeavouros-i3wm-setup/main/i3_install
chmod +x i3_install
./i3_install
# change keyboard shortcuts, predefined workspaces
```

#### Hyprland
```
hyperland xdg-desktop-portal-hyprland
```

### Terminal
```
bash zsh fish xonsh
oh-my-zsh-git zsh-theme-powerlevel10k
tmux foot alacritty
bottom htop
bat rsync wormhole-william time
zip unzip atool unrar
tldr dust atuin ripgrep thefuck
neofetch
zellij yazi ripdrag
# zsh4humans
```

#### Rust terminal
```
atuin bat bottom bustd dust eza fd ouch ripgrep yazi zellij
```

### Disk
```
baobab gnome-disk-utility gparted tokei
```

### Editors
```
visual-studio-code-bin idlex
micro neovim helix
mousepad libreoffice
tectonic pandoc texlive texlive-langczechslovak typst
```

### Programming
```
valgrind
git lazygit git-delta meld gitbutler-bin
rye uv ruff
hyperfine
cf-tool testlib dbg-macro
docker
```

# Setup

### Tailscale
```bash
pacman -S tailscale
systemctl enable --now tailscaled
tailscale up
tailscale set --ssh
```

### Keyboard

```bash
localectl set-x11-keymap us-sk_dia
localectl
```

### Make
```bash
# /etc/makepkg.conf
MAKEFLAGS="-j$(nproc --ignore 1)"
LDFLAGS="... -fuse-ld=mold"
RUSTFLAGS="... -C link-arg=-fuse-ld=mold"

PKGEXT='.pkg.tar'
SRCEXT='.src.tar'
```

### No beep
```bash
# /etc/modprobe.d/nobeep.conf
blacklist pcspkr
```

### Pacman
```bash
pacman-mirrors -f 0

# /etc/pacman.conf
# uncomment:
# Color, CheckSpace, ParallelDownloads=5, ILoveCandy
# [multilib]
```

### Nemo bulk rename
```bash
sudo pacman -S nemo gprename
sudo tee /usr/local/bin/gprename-nemo <<'EOB'
#!/bin/bash
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
filePath=$(urldecode "$1")
gprename "$(dirname "$filePath")"
EOB
sudo chmod +x /usr/local/bin/gprename-nemo
dconf write /org/nemo/preferences/bulk-rename-tool "b'gprename-nemo'"
```

### Thunar
Configure custom actions -> Terminal -> Command: `foot -D %f`
Preferences:
  Display:
    Remember view settings for each folder
    Text beside icons
    Date format: Today at 23:56:36
  Behavior:
    Show full directory paths in tab titles
  Advanced:
    Verify file checksum on copy: Always


### P10k
```bash
sudo ln -s /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme /usr/share/oh-my-zsh/themes/powerlevel10k.zsh-theme
```

### Zram
```bash
yay -S zram-generator zstd
sudo echo '[zram0]\nzram-size = ram * 3\ncompression-algorithm = lz4\nswap-priority = 200\n' >/etc/systemd/zram-generator.conf
systemctl daemon-reload
sudo systemctl start /dev/zram0
# don't forget to disable zswap using /etc/dracut.conf.d/...
```

### ZSH
```bash
# https://github.com/romkatv/zsh4humans
if command -v curl >/dev/null 2>&1; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
else
  sh -c "$(wget -O- https://raw.githubusercontent.com/romkatv/zsh4humans/v5/install)"
fi
```

### icon theme oomox-Airmail-Dark
```bash
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
```

### Autologin
```bash
#TODO greetd
```

### Slovensko obciansky
TODO

### SSH
```bash
# TODO ssh keys
# TODO ssh agent
sudo systemctl enable --now sshd.service
```

### Static IP
```bash
cd /etc/netctl
sudo cp examples/ethernet-static mystatic

# change Description, Interface, Address
# DNS=('1.1.1.1' '1.0.0.1')
# uncomment IP6
sudo -e mystatic

netctl verify mystatic
ip link set <enpXsY> down
netctl enable mystatic
netctl start mystatic
```

### Python

```bash
#install
pypy3 python-pipx

pipx ensurepath

pipx completions
# read and follow whats printed
```


### systemctl services
```
systemd-resolved
  - pozri wiki
  - sprav link /etc/resolv.conf na /run/...
  - package systemd-resolvconf
systemd-timesyncd
```
