# sed 's/#.*//; s/^\s*//; /^-/d; /^\s*$/d; s/^+ //' packages.md | yay -S --needed -

# Desktop Environments & Window Managers
# MacOS
+ alt-tab
+ nikitabobko/tap/aerospace
+ FelixKratz/formulae/borders
+ karabiner-elements
+ middleclick
+ ukelele

# System Core & Base
+ mold

# Boot & System Configuration
+ chezmoi
- man
- man-pages

# Network & Connectivity
- openssh
@ parsec
+ tailscale

# File Management & System Tools
+ baobab # disk usage
+ tokei # rust, cloc

# Shell & Terminal
## Shells
- bash
- zsh
+ fish
- xonsh
- xxh # copy shell over ssh
- oh-my-zsh-git
- zsh-theme-powerlevel10k

## Terminal Emulators
+ alacritty
+ ghostty
+ kitty

## Terminal Multiplexers
+ tmux
+ zellij

## Terminal Tools (Rust)
+ atuin           # history
+ bat             # cat
+ bat-extras      # man
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
+ fzf # go
+ glow # go
+ htop
+ lazydocker
- lazynpm
- magic-wormhole
+ nvtop
- ov # go
+ rsync
+ thefuck
@ gnu-time
- tldr++ # go, interactive tldr
+ up
+ unrar
+ unzip
- wormhole-william # go
+ zip

# Browsers & Internet
@ zen-browser
+ brave
+ qbittorrent

# Media & Graphics
## Image Tools
+ gimp
+ pinta

## Audio/Video
@ mpv
+ vlc
+ syncplay
+ yt-dlp

# Communication
+ discord
? geary
+ thunderbird
+ telegram-desktop
+ slack-desktop

# Development Tools

## AI
? shellgpt-git
+ ollama

## Text Editors & IDEs
+ helix # rust
+ libreoffice
+ micro # go
+ neovim
@ visual-studio-code
+ visidata
+ zed # rust

## Version Control
+ bliss # gitignore
+ difftastic
+ git
@ gitbutler
+ git-delta # rust
+ lazygit
+ meld

## Programming Languages
+ rustup
+ clang
+ gcc

### Python
- python
- python-odfpy
- python-pipx
- python-scipy
@ pypy3.10

## Programming Tools
+ valgrind
+ uv # rust
+ ruff # rust
+ mise # rust
+ hyperfine # rust
+ stress
? testlib
+ dbg-macro
@ docker
+ docker-compose

## Documentation & Publishing
+ evince
+ typst
+ tectonic
@ pandoc
+ texlive
+ texlive-langczechslovak
- aspell-sk

# Virtualization
+ utm

# Utilities & Misc
+ stretchly
