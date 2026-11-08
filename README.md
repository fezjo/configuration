# configuration

Personal configuration for Arch Linux (primary), macOS and Windows.

## Current Linux stack

- niri compositor
- Dux Shell / DMS (`dux-shell`)
- greetd + agreety, with autologin into niri
- fish as the primary shell; minimal bash/zsh
- ghostty terminal
- Zen browser (qutebrowser as an offline fallback)
- systemd-boot, mkinitcpio, btrfs root on LUKS

## Layout

```text
linux/
  archinstall-no_disk_user.json  # prefilled archinstall config; disk/user via TUI
  packages_niri.md               # full package list ('+' enabled, '-' disabled)
  1-pre_installation.sh          # bootstrap, chaotic-aur, yay
  2-install_packages.sh          # install packages_niri.md
  3-post_installation.sh         # chezmoi, services, optional tools
  4-memory.sh                    # zram + swapfile + systemd-oomd
  setup.sh                       # full install flow
  system/apply.py                # file-only manifest runner
  system/manifest.toml           # files and file edits
  root/                          # system files deployed by system/apply.py
  chezmoi/                       # home-directory source of truth
archive/                         # old desktops/scripts, not deployed
macos/                           # kept, separate setup
windows/                         # kept
```

## Install

1. Boot the Arch ISO and run `archinstall --config linux/archinstall-no_disk_user.json`.
   Select the disk in the TUI. The user is prefilled as `fezjo`; if you need a
   different name, replace all occurrences before running archinstall — the TUI
   user alone is not enough.
2. First boot: clone this repository and run `bash linux/setup.sh`.

   The archinstall user is hardcoded as `fezjo` in the JSON, greetd config, and
   custom commands. Replace that string if you want another account. Change the
   hostname and the throwaway password hash in the TUI before installing.

Local checks: `make check` (bash/sh/zsh/fish syntax, JSON, Python syntax, and
niri config).

`setup.sh` runs the pre-install step, installs the package list, applies
chezmoi, runs the memory setup, and applies system configuration. Run it as
your user, not as root.

## Environment

`~/.config/environment.d/*.conf` is the single source for XDG directories and
tool-specific paths. It is read by the systemd user manager and loaded by
`.profile`, bash, zsh and fish for TTY/SSH sessions.

`~/.config/shell/env.sh` is the shell loader. Do not duplicate XDG/tool paths in
individual shell files.

## System configuration

`linux/system/apply.py` is file-only and reads `manifest.toml`:

```bash
sudo python3 linux/system/apply.py --plan
sudo python3 linux/system/apply.py --diff
sudo python3 linux/system/apply.py --check
sudo python3 linux/system/apply.py --apply
# activation happens in 3-post_installation.sh
```

It patches `pacman.conf`/`faillock.conf`, installs makepkg drop-ins, greetd
config, keyd, sudoers, xkb, `dbg.h`, OOM drop-ins, and SysRq settings. The repo
keeps no full-file copies of `pacman.conf`, `makepkg.conf`, or `faillock.conf`;
the live files are patched or receive drop-ins.

Timeshift is configured from the current root/LUKS UUIDs:

```bash
sudo bash linux/system/timeshift.sh --dry-run
sudo bash linux/system/timeshift.sh --yes
```

It writes `/etc/timeshift/timeshift.json`; create the first snapshot with
`sudo timeshift --create --comments initial`. Home is intentionally not
included in snapshots.

## Universal clipboard

`Mod+C` and `Mod+V` send the focused application's native shortcuts:

- terminals: `Ctrl+Shift+C` / `Ctrl+Shift+V`
- GUI applications: `Ctrl+C` / `Ctrl+V`

This preserves text, images, files, and rich clipboard data. It needs `niri`,
`jq`, and `wtype`. `Ctrl+Insert` / `Shift+Insert` remain untouched and work
where the application supports them.

`Mod+Alt+V` opens the DMS clipboard history.

The old niri `Mod+C` column-center action is now `Mod+Shift+C`.

## OOM and SysRq

`4-memory.sh` sets up zram, the disk swapfile overflow, and systemd-oomd.
`kernel.sysrq = 244` enables the useful emergency subset:

- `Alt+SysRq+F` — invoke the OOM killer
- `Alt+SysRq+E` — SIGTERM all except init
- `Alt+SysRq+I` — SIGKILL all except init
- `Alt+SysRq+S` — sync
- `Alt+SysRq+U` — remount read-only
- `Alt+SysRq+B` — reboot

## Secrets

`.config/Code/User/settings.json` is ignored because the live file is
application-managed and may contain extension API keys. Do not run a blanket
`chezmoi add ~/.config`.

`.ssh/config` and `.ssh/known_hosts` are stored as age-encrypted chezmoi files.
The age recipient is the public key from `~/.ssh/ssh_fezjo.pub`; decryption
uses the private key `~/.ssh/ssh_fezjo`. Copy that key from a trusted backup
before running `setup.sh`; it is not stored here. Install `age` from the package
list on new machines. The deployed chezmoi config expects the repository at
`~/src/configuration`; change `sourceDir` if you clone elsewhere.

Note that earlier git history still contains the old plaintext SSH files; the
encryption protects the current tree, not historical commits.

## Archive

`archive/` contains the old sway/i3/rofi/zsh4humans/xonsh/LunarVim setup and
scripts tied to those environments. It is not deployed.
