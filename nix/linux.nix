{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ## Budgie/GNOME Components
        dconf
        dconf-editor
        budgie-control-center
        # gnome-control-center
        lxappearance-gtk3
        nwg-look
        seahorse
        gnome-power-manager
        gnome-clocks

    ## Launchers
        rofi-wayland
        rofi-calc-git

    ## X11 Tools
        xorg-xkill
        xorg-xev
        xorg-xeyes

    ## Wayland Tools
        wev
        wdisplays
        xorg.xwayland
        xdg-desktop-portal-wlr
        grim
        slurp
        wl-clipboard
        kanshi
        wlsunset

    # System Core & Base
        base
        base-devel
        linux-lts
        linux-tools
        man
        man-pages
        polkit
        gnome-keyring
        polkit-gnome
        xdg-desktop-portal
        xdg-desktop-portal-gtk

    # Daemons & Services
        systemd-resolvconf
        # bustd           # oom
        batsignal

    # Boot & System Configuration
        dracut
        efibootmgr
        gnome-firmware
        man-pages
        etckeeper
        xdg-ninja
        antidot-bin

    # Disk
        btrfs-desktop-notification
        timeshift
        timeshift-autosnap

    # Network & Connectivity
        blueman
        bluez
        bluez-utils
        netctl
        networkmanager
        openbsd-netcat
        openssh

    # File Management & System Tools
        thunar
        gnome-disk-utility
        gparted
        szyszka-bin # rust, batch rename

    # Shell & Terminal
    ## Terminal Emulators
        foot

    # Media & Graphics
    ## Image Tools
        feh
        viewnior
        flameshot
        swww
        waypaper-git # chaotic-aur

    ## Audio/Video
        # play-with-mpv
        pamixer
        kooha
        cheese

    # Communication
        geary

    # Development Tools
    ## Text Editors & IDEs
        mousepad

    # Virtualization
    qemu-desktop
    libvirt
    quickemu
    virt-manager
    virtualbox

    # Utilities & Misc
        keyd
        solaar
        safeeyes
        redshift
        pscircle
        tk
        wine

    # Fonts
        # ttf-roboto-mono-nerd
        ttf-hack-nerd
        ttf-firacode-nerd
        noto-fonts-emoji
        # ttf-ms-win11-auto
  ];
}
