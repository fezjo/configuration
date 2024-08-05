/etc/makepkg.conf
MAKEFLAGS="-j$(nproc --ignore 1)"

/etc/modprobe.d/nobeep.conf
blacklist pcspkr

pacman-mirrors -f 0

/etc/pacman.conf
ILoveCandy
enable multilib

sudo pacman -S nemo gprename
sudo tee /usr/local/bin/gprename-nemo <<'EOB'
#!/bin/bash
function urldecode() { : "${*//+/ }"; echo -e "${_//%/\\x}"; }
filePath=$(urldecode "$1")
gprename "$(dirname "$filePath")"
EOB
sudo chmod +x /usr/local/bin/gprename-nemo
dconf write /org/nemo/preferences/bulk-rename-tool "b'gprename-nemo'"

sudo ln -s /usr/share/zsh-theme-powerlevel10k/powerlevel10k.zsh-theme /usr/share/oh-my-zsh/themes/powerlevel10k.zsh-theme

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
mousepad nemo
pscircle
cf-tool time zip unzip atool
xonsh python-pip python-sympy 
man-pages nemo-samba wsdd
unrar
firacode noto-fonts-emoji
geary gnome-control-center
parsec-bin
linux-tools

i3-wm i3exit i3lock polybar rofi dunst alacritty

kooha geogebra? bottom cheese gnome-clocks gnome-power-statistics   

yay -S zram-generator
sudo echo '[zram0]\nzram-size = ram * 1.5\ncompression-algorithm = lz4\nswap-priority = 200\n' >/etc/systemd/zram-generator.conf
systemctl daemon-reload
sudo systemctl start /dev/zram0

#icon theme oomox-Airmail-Dark
gsettings set org.gnome.desktop.interface gtk-theme Adwaita-dark
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
