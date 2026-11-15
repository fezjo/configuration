# Common packages for every machine.
#
# '+' enables a package, '-' disables it. Higher layers (form, cpu, compositor,
# shell, role, host) can add packages or remove packages added here.

# Most essential
+ fish
+ helix
+ htop
+ ghostty
+ git
+ mold
+ iwd
+ networkmanager
+ qutebrowser

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
+ wtype
+ wlsunset
- xdg-desktop-portal-wlr # not used by niri
+ xdg-desktop-portal-gnome

# System
+ linux-firmware
## Base tools
+ man-db
+ man-pages
+ pacman-contrib
+ sudo
+ wget
+ zram-generator
## Boot
- dracut
## Daemons & Services
+ greetd
+ greetd-agreety
+ gnome-keyring
+ polkit
+ polkit-gnome
+ xdg-desktop-portal
+ xdg-desktop-portal-gtk
+ systemd-resolvconf
+ cronie
- bustd           # oom
## Network & Connectivity
+ blueman
+ bluez
+ bluez-utils
+ netctl
+ networkmanager
+ openbsd-netcat
+ localsend # local file sharing
+ openssh
+ parsec-bin
+ proton-vpn-gtk-app
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
+ sshfs
+ stress-ng
- szyszka-bin # rust, batch rename

# System Configuration
+ chezmoi
+ age
- etckeeper
- xdg-ninja
- antidot-bin
+ gnome-firmware
+ upower

# Shell & Terminal
## Shells
+ bash
+ zsh
+ fish
+ zsh-autosuggestions
+ zsh-syntax-highlighting
## Terminal Emulators
+ foot
+ ghostty
+ kitty
+ wezterm-git
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
+ jq
+ glow # go
+ lazydocker
+ ripdrag
+ rsync
+ time
+ up # ultimate plumber
## Monitoring
+ bottom
+ htop
+ nvtop

# Gui
+ gnome-clocks
+ thunar
+ qbittorrent
## Browsers
+ zen-browser-bin
+ brave-bin
+ qutebrowser
## Communication
+ discord
+ telegram-desktop
+ slack-desktop

# Media & Graphics
## Image Tools
+ feh
+ gimp
+ imagemagick
+ inkscape
+ pinta
+ viewnior
+ flameshot
## Audio/Video
+ mpv
+ vlc
+ vlc-plugins-all
+ syncplay
+ yt-dlp
+ pamixer
+ pavucontrol
+ audacity
- cheese
## Media Apps
+ amberol # music player
+ bookworm # ebook reader
+ cozy-audiobooks # audiobook player
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
+ opencode-desktop
## Text Editors & IDEs
+ helix # rust
+ micro # go
+ mousepad
+ nano
+ neovim
+ visual-studio-code-bin
+ visidata
+ zed # rust
## Version Control
+ git
+ jujutsu # jj
+ bliss # gitignore
+ difftastic
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
+ perf
+ valgrind
+ uv # rust
+ ruff # rust
+ mise # rust
+ hyperfine # rust
+ testlib
- dbg-macro
+ docker
+ docker-compose

# Virtualization
+ qemu-desktop
+ libvirt
+ quickemu-git
+ virt-manager
+ virtualbox
+ virtualbox-host-dkms
+ distrobox
+ podman
+ podman-compose
+ podman-desktop
+ wine

# Fonts
+ ttf-firacode-nerd
+ ttf-hack-nerd
+ ttf-iosevkaterm-nerd
+ ttf-roboto-mono-nerd
+ noto-fonts
+ noto-fonts-emoji
+ noto-fonts-cjk
+ ttf-dejavu
+ ttf-liberation
- ttf-ms-win11-auto

# Check out later
- rustdesk # teamviewer
- rnote # xournal++
- waydroid # android on linux
- cassowary # windows apps on linux
- wild # linker
- sd # ianthehenry
