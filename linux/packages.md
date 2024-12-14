# sed 's/#.*//; s/^\s*//; /^-/d; /^\s*$/d; s/^+ //' packages.md | yay -S --needed -

# System Core & Base
+ base
+ base-devel
+ linux-tools
+ mold
+ man
+ man-pages
+ polkit
+ gnome-keyring
+ polkit-gnome
+ xdg-desktop-portal

# Daemons & Services
+ systemd-resolvconf

# Boot & System Configuration
+ dracut
+ efibootmgr
+ chezmoi
+ xdg-ninja
+ antidot-bin

# Desktop Environments & Window Managers
## Budgie/GNOME Components
+ dconf
+ dconf-editor
+ budgie-control-center
+ gnome-control-center
+ lxappearance-gtk3
+ seahorse
+ gnome-power-statistics
+ gnome-clocks

## Window Managers
- polybar
+ rofi
+ rofi-calc

### i3
- i3-wm
- i3-exit
- i3lock

### sway
- sway
- swaylock
- swayidle
- sway-systemd
- waybar

### hyperland
- hyperland
- xdg-desktop-portal-hyprland

## X11 Tools
+ xorg-xkill
+ xorg-xev
+ xorg-xeyes

## Wayland Tools
+ wev
+ wdisplays
+ xorg-wayland
+ xdg-desktop-portal-wlr
+ grim
+ slurp
+ wl-copy
+ kanshi
+ wlsunset

# Network & Connectivity
+ tailscale
+ openssh
+ netctl
+ bluez
+ bluez-utils
+ blueman
+ nm-applet
+ networkmanager
+ parsec-bin

# File Management & System Tools
+ thunar
+ baobab
+ gnome-disk-utility
+ gparted
+ tokei

# Shell & Terminal
## Shells
+ bash
+ zsh
+ fish
+ xonsh
+ oh-my-zsh-git
+ zsh-theme-powerlevel10k
+ zsh4humans

## Terminal Emulators
+ foot
+ alacritty

## Terminal Multiplexers
+ tmux
+ zellij

## Terminal Tools (Rust)
+ bottom
+ bat
+ dust
+ atuin
+ ripgrep
+ yazi
+ eza
+ fd
+ ouch
+ bustd

## Terminal Tools (Non-Rust)
+ htop
+ rsync
- magic-wormhole
- wormhole-william
+ wormhole-rs-bin
+ time
+ ov
+ zip
+ unzip
+ atool
+ unrar
+ tldr
+ thefuck
+ neofetch
+ ripdrag
+ glow

# Browsers & Internet
+ zen-browser-bin
+ floorp
+ firefox
+ chromium
+ qbittorrent

# Media & Graphics
## Image Tools
+ feh
+ gimp
+ pinta
+ viewnoir
+ flameshot

## Audio/Video
+ mpv
+ syncplay
+ yt-dlp
- play-with-mpv
+ pamixer
+ mpd
+ ncmpcpp
+ audacity
+ kooha
+ cheese

# Communication
+ discord
+ geary
+ telegram-desktop
+ slack

# Development Tools
## Text Editors & IDEs
+ visual-studio-code-bin
+ zed
+ micro
+ neovim
+ helix
+ mousepad
+ libreoffice

## Version Control
+ git
+ lazygit
+ git-delta
+ meld
+ gitbutler-bin

## Programming Languages
+ rustup
+ clang
+ gcc

### Python
+ python
+ python-pipx
+ pypy3
+ python-scipy

## Programming Tools
+ valgrind
+ rye
+ uv
+ ruff
+ mise
+ hyperfine
+ cf-tool
+ testlib
+ dbg-macro
+ docker

## Documentation & Publishing
+ typst
+ tectonic
+ pandoc
+ texlive
+ texlive-langczechslovak
+ aspell-sk

# Virtualization
+ qemu-desktop
+ libvirt
+ quickemu
+ virt-manager
+ virtualbox
+ distrobox

# Utilities & Misc
+ keyd
+ solaar
+ stretchly
+ safeeyes
+ redshift
+ pscircle
+ tk
+ wine

# Fonts
+ ttf-roboto-mono-nerd
+ ttf-hack-nerd
+ ttf-firacode-nerd
+ noto-fonts-emoji
- ttf-ms-win11-auto
