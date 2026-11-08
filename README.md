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
   Select the disk and user in the TUI. The config pre-fills the rest.
2. First boot: clone this repository and run `sudo bash linux/setup.sh`.

Local checks: `make check` (bash/sh/zsh/fish syntax, JSON, and niri config when
the generated DMS fragments are present).

`setup.sh` runs the pre-install step, installs the package list, applies
chezmoi, runs the memory setup, and applies system configuration.

## Environment

`~/.config/environment.d/*.conf` is the single source for XDG directories and
tool-specific paths. It is read by the systemd user manager and loaded by
`.profile`, bash, zsh and fish for TTY/SSH sessions.

`~/.config/shell/env.sh` is the shell loader. Do not duplicate XDG/tool paths in
individual shell files.

## System configuration

`linux/system/apply.py` is file-only and reads `manifest.toml`:

```bash
python3 linux/system/apply.py --plan
python3 linux/system/apply.py --diff
python3 linux/system/apply.py --check
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

`setup-universal-clipboard` removes DMS's default `Mod+V` binding so niri can own
the key. `3-post_installation.sh` runs it after chezmoi.

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

`.config/Code/User/settings.json` is ignored by chezmoi because it contains
extension API keys. Do not run a blanket `chezmoi add ~/.config`.

`.ssh/config` and `.ssh/known_hosts` are stored as age-encrypted chezmoi files.
The age identity lives outside the repository at `~/.config/age/keys.txt`.
Install `age` from the package list on new machines.

Note that earlier git history still contains the old plaintext SSH files; the
encryption protects the current tree, not historical commits.

## Archive

`archive/` contains the old sway/i3/rofi/zsh4humans/xonsh/LunarVim setup and
scripts tied to those environments. It is not deployed.
