## CTT winutil

- https://github.com/ChrisTitusTech/winutil
```ps
irm "https://christitus.com/win" | iex
```

Activate windows

# Settings

## Programs
- File explorer
	- Settings
		- View
			- Show encrypted or compressed NTFS files in colour
			- Use checkboxes to select items
			- Hide extensions for known file types
- Task manager
	- Pin to taskbar
	- Switch to logical cores view
- Windows terminal
	- Set as default
	- Create Admin profile
- Firefox
	- Login to Firefox account
	- Transfer extensions settings

## Settings panel
- System
	- Display
		- Night light
		- Set high refresh rate
	- Power
		- Power mode
	- Multi-tasking
		- Show tabs from apps when snapping
	- Clipboard
		- Clipboard history
- Bluetooth & Devices
	- Mouse
		- Additional mouse settings
			- Pointer options
				- Enhance pointer precision
- Personalization
	- Colours
		- Choose your mode
	- Background
		- Dark default background
	- Taskbar
		- Turn off widgets and chat
		- Taskbar behaviours
			- Taskbar alignment
- Time & Language
	- Set proper keyboard layouts
- Windows update
	- Update Windows
	- Advanced options
		- Optional Updates

# Execute

## Installers setup
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

Set-ExecutionPolicy RemoteSigned -Scope CurrentUser # Optional: Needed to run a remote script the first time
irm get.scoop.sh | iex
scoop bucket add extras
```

## Installers run
```
choco install 7zip bitwarden chocolateygui coretemp crystaldiskinfo discord firefox furmark gimp git hwinfo libreoffice microsoft-windows-terminal mpv notepadplusplus parsec powertoys python qbittorrent spotify steam syncplay telegram vlc vscode windirstat yt-dlp
```

## WSL
```
dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /featurename:VirtualMachinePlatform /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
```

restart Windows

```
wsl --update
scoop install archwsl
wsl
```
