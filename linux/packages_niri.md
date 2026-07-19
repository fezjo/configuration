# sed 's/#.*//; s/^\s*//; /^-/d; /^\s*$/d; s/^+ //' packages.md | yay -S --needed -

# Most essential
## Installation
+ base-devel
+ git
+ mold
## Usage
+ fish
+ helix
+ htop
+ ghostty
+ niri
+ wdisplays
+ firefox
+ iwctl

# Desktop Environments & Window Managers
## Configuration
- dconf
- dconf-editor
- budgie-control-center
- gnome-control-center
+ keyd
+ solaar
+ nwg-look # GTK theme settings
+ seahorse # Manage GPG Keys

## X11 Tools
+ xorg-xkill
+ xorg-xev
+ xorg-xeyes

## Wayland Tools
+ wdisplays
+ wev
+ wl-clipboard
+ wlsunset
+ xdg-desktop-portal-wlr
+ xorg-xwayland
+ xwayland-satellite

# Niri
+ niri

## DankMaterialShell
+ quickshell-git
+ dms-shell-niri
+ matugen
+ cava
+ adw-gtk-theme

# System
+ linux-lts
## Base tools
+ arch-install-scripts
+ base
+ base-devel
+ linux-tools
+ man-db
+ man-pages
## Boot
- dracut
+ efibootmgr
+ mkinitcpio
+ systemd-boot
## Daemons & Services
+ gnome-keyring
+ polkit
+ polkit-gnome
+ xdg-desktop-portal
+ xdg-desktop-portal-gtk
+ systemd-resolvconf
- bustd           # oom
## Network & Connectivity
+ blueman
+ bluez
+ bluez-utils
+ netctl
+ networkmanager
+ openbsd-netcat
+ openssh
+ parsec-bin
+ tailscale
+ waypipe
## Disk & File Management
+ btrfs-desktop-notification
+ timeshift
+ timeshift-autosnap
+ baobab # disk usage
+ dua-cli
+ gnome-disk-utility
+ gparted
+ tokei # rust, cloc
+ stress-ng
- szyszka-bin # rust, batch rename

# System Configuration
+ chezmoi
- etckeeper
- xdg-ninja
- antidot-bin
+ gnome-firmware

# Shell & Terminal
## Shells
+ bash
+ zsh
+ fish
## Terminal Emulators
+ foot
+ ghostty
+ kitty
+ wezterm
## Terminal Multiplexers
+ tmux
+ zellij
## Terminal Tools (Rust)
+ atuin           # history
+ bat             # cat
+ bat-extras      # man
+ choose          # cut
+ dust            # du
+ eza             # ls
+ fd              # find
+ mdfried         # markdown preview
+ ouch            # atool
+ ripgrep         # grep
+ sd              # sed
+ tealdeer        # tldr
+ wormhole-rs-bin # magic-wormhole
+ yazi            # filemanager
+ zoxide          # cd
## Terminal Tools (Non-Rust)
+ fastfetch
+ fzf # go
+ glow # go
+ lazydocker
+ ripdrag
+ rsync
+ time
+ up # ultimate plumber
## Monitoring
+ bottom
+ gnome-power-manager
+ htop
+ nvtop

# Gui
+ gnome-clocks
+ thunar
+ qbittorrent
## Browsers
+ zen-browser-bin
+ brave
## Communication
+ discord
+ telegram-desktop
+ slack-desktop

# Media & Graphics
## Image Tools
+ feh
+ gimp
+ pinta
+ viewnior
+ flameshot
## Audio/Video
+ mpv
+ vlc
+ syncplay
+ yt-dlp
+ pamixer
+ audacity
- cheese
## Documents
+ aspell-sk
+ evince
+ libreoffice-still
+ pandoc-bin
+ tectonic
+ typst

# Development Tools
## AI
- shellgpt-git
- ollama
+ opencode-desktop-bin
## Text Editors & IDEs
+ helix # rust
+ micro # go
+ mousepad
+ neovim
+ visual-studio-code-bin
+ visidata
+ zed # rust
## Version Control
+ bliss # gitignore
+ difftastic
+ git
- gitbutler-bin
+ git-delta # rust
+ lazygit
+ meld
## Compilation & Linking
+ rustup
+ clang
+ gcc
+ lld
+ mold
+ wild
## Python
+ python
+ python-odfpy
+ python-pipx
+ python-scipy
+ pypy3
## Programming Tools
+ valgrind
+ uv # rust
+ ruff # rust
+ mise # rust
+ hyperfine # rust
+ testlib
+ dbg-macro
+ docker
+ docker-compose

# Virtualization
+ qemu-desktop
+ libvirt
+ quickemu
+ virt-manager
+ virtualbox
+ virtualbox-host-modules-arch
+ virtualbox-host-modules-lts
+ distrobox
+ wine

# Fonts
+ ttf-firacode-nerd
+ ttf-hack-nerd
+ ttf-iosevkaterm-nerd
+ ttf-roboto-mono-nerd
+ noto-fonts-emoji
- ttf-ms-win11-auto

# Check out later
- rustdesk # teamviewer
- rnote # xournal++
- waydroid # android on linux
- cassowary # windows apps on linux
- wild # linker
- sd # ianthehenry
