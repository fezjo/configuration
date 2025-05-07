{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Core utilities
        mold

    # Boot & System Configuration
        chezmoi
        man-db
        kanata

    # Networking & Connectivity
        openssh
        parsec
        rustdesk
        tailscale

    # File Management
        baobab # disk usage
        tokei # rust, cloc

    # Shells & Terminals
    ## Shells
        # bash
        # zsh
        fish
        # xonsh
        # xxh
        # oh-my-zsh
        # zsh-theme-powerlevel10k

    ## Terminal Emulators
        allacritty
        ghostty
        kitty

    ## Terminal Multiplexers
        tmux
        zellij

    ## Terminal Tools (Rust)
        atuin           # history
        bat             # cat
        bat-extras      # man
        bottom          # htop
        choose          # cut
        dust            # du
        eza             # ls
        fd              # find
        ouch            # atool
        ripgrep         # grep
        sd              # sed
        tealdeer        # tldr
        wormhole-rs-bin # magic-wormhole
        yazi            # filemanager
        zoxide          # cd

    ## Terminal Tools (Non-Rust)
        atool
        fastfetch
        fzf # go
        glow # go
        htop
        lazydocker
        # lazynpm
        # magic-wormhole
        nvtop
        # ov # go
        rsync
        thefuck
        # tldr++ # go, interactive tldr
        up
        unrar
        unzip
        # wormhole-william # go
        zip

    # Browsers & Internet
        zen-browser-bin
        # firefox
        # floorp
        # brave
        # chromium
        qbittorrent

    # Media & Graphics
    ## Image Tools
        gimp
        pinta

    ## Audio/Video
        mpv
        vlc
        syncplay
        yt-dlp
        # mpd
        # ncmpcpp
        audacity

    # Communication
        discord
        thunderbird
        telegram-desktop
        slack-desktop

    # Development tools
    ## AI
        shellgpt-git
        ollama

    ## Text Editors & IDEs
        helix # rust
        libreoffice
        micro # go
        neovim
        vscode
        visidata
        zed # rust

    ## Version Control
        bliss # gitignore
        difftastic
        git
        gitbutler-bin
        git-delta # rust
        lazygit
        meld

    ## Programming Languages
        rustup
        clang
        gcc

    ### Python
        python
        python-odfpy
        python-pipx
        python-scipy
        pypy3

    ## Programming Tools
        valgrind
        uv # rust
        ruff # rust
        mise # rust
        hyperfine # rust
        testlib
        dbg-macro
        docker
        docker-compose

    ## Documentation & Publishing
        evince
        typst
        tectonic
        pandoc
        texlive
        texlive-langczechslovak
        aspell-sk
  ];
}
