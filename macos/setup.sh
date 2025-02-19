#!/bin/bash

# Install Homebrew
if ! which brew > /dev/null; then
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
	echo >> /Users/fezjo/.zprofile
	echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> /Users/fezjo/.zprofile
	eval "$(/opt/homebrew/bin/brew shellenv)"
else
	echo "Homebrew already installed"
fi

brew install fish helix htop zen-browser telegram-desktop

brew install \
	mold \
	chezmoi \
	baobab tokei \
	fish xonsh xxh \
	ghostty \
	zellij \
	atuin bat bat-extras bottom choose dust eza fd ouch ripgrep sd tealdeer magic-wormhole.rs yazi zoxide \
	atool fastfetch fzf glow htop lazydocker lazygit nvtop rsync thefuck gnu-time up unzip zip \
	zen-browser qbittorrent \
	gimp \
	vlc syncplay yt-dlp \
	discord thunderbird telegram-desktop slack \
	ollama \
	helix libreoffice micro neovim zed \
	git git-delta \
	rustup gcc \
	pypy3.10 \
	valgrind uv ruff mise hyperfine docker-compose \
	typst tectonic pandoc texlive aspell \
	utm
brew install --cask tailscale mpv docker
brew install nikitabobko/tap/aerospace bettertouchtool

brew install ollama
brew services start ollama docker


cat << __EOF__
# Change these settings:
Name = https://www.nordicnames.de/w/index.php?title=Norwegian_Statistics_of_1781%2d1800
Acessibility
	Zoom
		User scroll gesture with modfier keys to zoom = On
	Display
		Reduce motion = On
Appearance
	Appearance = Auto
Control Center
	Modules
		Sound = Always Show
	Battery
		Show Percentage = On
		Show Energy Mode = Always
	Music Recognition
		Show in Control Center = On
	Keyboard Brightness
		Show in Control Center = On
	Automatically hide and show the menu bar = Never
Desktop & Dock
	Size = 10%
	Position on screen = Left
	Minimize windows using = Scale Effect
Displays
	Scaling = More Space
	Night Shift
		Schedule = Sunset to Sunrise
		Color temperature = 100% More Warm
	Advanced
		Show resolutions as list = On
Spotlight
	Search results
		Websites = Off
	Help Apple Improve Search = Off
Wallpaper
	Shuffle Landscape
Sound
	Play sound on startup = Off
Lock Screen
	Start Screen Saver when inactive = For 2 minutes
	Turn display off on battery when inactive = For 3 minutes
	Turn display off on power adapter when inactive = For 3 minutes
	Require password after screen saver begins or display is turned off = After 5 seconds
	Show message when locked = On
		Set = Jozef Ciz +421949047023
Keyboard
	Key repeat rate = Fastest
	Delay until repeat = Shortest
	Press 🌐 key to = Show Emoji & Symbols
Trackpad
	More Gestures
		App Expose = Swipe Down with Three Fingers
Function Keys
	Use F1, F2... = On
Modifier Keys
	Caps Lock key = Escape

# Setup Terminal
Copy Basic profile
Text
	Cursor = Vertical Bar
Window
	Window Size
		Columns = 100
		Rows = 40
Shell
	Startup
		Run command = /opt/homebrew/bin/fish
		Run inside shell = Off
	When the shell exits = Close if the shell exited cleanly

# Dock
Remove all things except zen-browser, telegram, terminal

# Docker
Open application, Accept agreement, Choose recommended settings, Type password, Install Rossetta2
Verify using `docker run hello-world`

# Tailscale
Open application
Look into menubar

# Telegram
Scaling = 75%
Notifications and Sounds
	Include muted chats in unread count = Off
	Include muted chats in folder counters = Off

# Notifications
Check that notifications for all relevant programs are enabled

# Aerospace
System Settings → Desktop & Dock → Group windows by application
System Settings → Desktop & Dock → Displays have separate Spacesi
/opt/homebrew/bin/aerospace workspace "$(/opt/homebrew/bin/aerospace list-workspaces --monitor mouse --visible)" && /opt/homebrew/bin/aerospace workspace next

# TODO
en_skdia keyboard layout
backtick/tilda
slow spotlight
slow animations
enable swap
move configs
middle click

# startup
aerospace bettertouchtool docker tailscale telegram
__EOF__
