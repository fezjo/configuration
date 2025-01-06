# sed 's/#.*//; s/^\s*//; /^-/d; /^\s*$/d; s/^+ //' packages.md | yay -S --needed -

# System Core & Base
+ base
+ base-devel
+ linux-lts
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
- bustd           # oom

# Boot & System Configuration
+ dracut
+ efibootmgr
+ chezmoi
+ etckeeper
+ xdg-ninja
+ antidot-bin

# Disk
+ btrfs-desktop-notification
+ timeshift
+ timeshift-autosnap

# Desktop Environments & Window Managers
## Budgie/GNOME Components
+ dconf
+ dconf-editor
+ budgie-control-center
- gnome-control-center
+ lxappearance-gtk3
+ nwg-look
+ seahorse
+ gnome-power-manager
+ gnome-clocks

## Window Managers
- polybar
+ rofi-wayland
+ rofi-calc-git

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
+ xorg-xwayland
+ xdg-desktop-portal-wlr
+ grim
+ slurp
+ wl-clipboard
+ kanshi
+ wlsunset

# Network & Connectivity
+ blueman
+ bluez
+ bluez-utils
+ netctl
+ networkmanager
+ openbsd-netcat
+ openssh
+ parsec-bin
+ tailscale

# File Management & System Tools
+ thunar
+ baobab # disk usage
+ gnome-disk-utility
+ gparted
+ tokei # rust, cloc
+ stress-ng
+ szyszka-bin # rust, batch rename

# Shell & Terminal
## Shells
+ bash
+ zsh
+ fish
+ xonsh
+ oh-my-zsh-git
+ zsh-theme-powerlevel10k

## Terminal Emulators
+ alacritty
+ foot
+ ghostty

## Terminal Multiplexers
+ tmux
+ zellij

## Terminal Tools (Rust)
+ atuin           # history
+ bat             # cat
+ bottom          # htop
+ choose          # cut
+ dust            # du
+ eza             # ls
+ fd              # find
+ ouch            # atool
+ ripgrep         # grep
+ sd              # sed
+ tealdeer        # tldr
+ wormhole-rs-bin # magic-wormhole
+ yazi            # filemanager
+ zoxide          # cd

## Terminal Tools (Non-Rust)
+ atool
+ fastfetch
+ fortune-mod
+ fzf # go
+ glow # go
+ htop
- magic-wormhole
+ nvtop
- ov # go
+ ripdrag
+ rsync
+ thefuck
+ time
- tldr++ # go, interactive tldr
+ unrar
+ unzip
- wormhole-william # go
+ zip

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
+ viewnior
+ flameshot
+ swww
+ waypaper-git # chaotic-aur

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
+ thunderbird
+ telegram-desktop
+ slack

# Development Tools
## Text Editors & IDEs
+ helix # rust
+ libreoffice
+ micro # go
+ mousepad
+ neovim
+ visual-studio-code-bin
+ zed # rust

## Version Control
+ git
+ lazygit # go
+ git-delta # rust
+ meld
+ gitbutler-bin

## Programming Languages
+ rustup
+ clang
+ gcc

### Python
+ python
+ python-pipx
+ python-scipy
+ pypy3

## Programming Tools
+ valgrind
+ rye # rust
+ uv # rust
+ ruff # rust
+ mise # rust
+ hyperfine # rust
+ cf-tool
+ testlib
+ dbg-macro
+ docker

## Documentation & Publishing
+ evince
+ typst
+ tectonic
+ pandoc-bin
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
- ttf-roboto-mono-nerd
+ ttf-hack-nerd
+ ttf-firacode-nerd
+ noto-fonts-emoji
- ttf-ms-win11-auto
