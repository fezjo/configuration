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

`setup.sh` runs the pre-install step, installs the package list, configures
memory, applies system files, runs the post-install step (chezmoi and
services), and configures Timeshift. Run it as your user, not as root.

Preview the whole flow without changing anything:

```bash
bash linux/setup.sh --dry-run
```

Each stage also supports `--dry-run` (`1-pre`, `2-install`, `3-post`) or an
equivalent preview (`4-memory.sh --dry-run`, `system/apply.py --diff`,
`system/timeshift.sh --dry-run`). The package stage splits its output into
packages that would be installed, packages that would be updated, and a count
of packages already up to date (which are not listed). `1-pre --dry-run`,
`2-install --dry-run`, `3-post --dry-run`, and `4-memory.sh --dry-run` do not
need root. `setup.sh --dry-run` still runs the full `apply.py --diff` with sudo
because some manifest targets, such as `/etc/sudoers.d`, are root-only.

`1-pre_installation.sh` installs `reflector`, backs up
`/etc/pacman.d/mirrorlist` once to
`/etc/pacman.d/mirrorlist.bak-pre-reflector`, selects the 20 most recently
synced HTTPS mirrors in Slovakia, Czechia, Austria, and Germany by download
rate, and re-syncs before installing the bootstrap tools. If reflector fails,
it restores the backup first. Override `REFLECTOR_COUNTRIES` to change the
list; set it to an empty value to disable the country filter.

It then installs `python` and applies only the pacman and makepkg entries from
`system/manifest.toml` through `system/apply.py --filter`. This means
`2-install_packages.sh` runs with the final pacman and makepkg configuration
instead of ad-hoc `sed`/`cp` edits.

`3-post --dry-run` checks `systemctl is-enabled` and `systemctl is-active` and
reports the predicted enable/start/restart state changes instead of printing
the raw commands.

## Environment

`~/.config/environment.d/*.conf` is the single source for XDG directories and
tool-specific paths. It is read by the systemd user manager and loaded by
`.profile`, bash, zsh and fish for TTY/SSH sessions.

`~/.config/shell/env.sh` is the shell loader. Do not duplicate XDG/tool paths in
individual shell files.

## System configuration

`linux/system/apply.py` is file-only and reads `manifest.toml`. It requires
Python 3.11 or newer because it uses the standard-library `tomllib`:

```bash
sudo python3 linux/system/apply.py --plan
sudo python3 linux/system/apply.py --diff
sudo python3 linux/system/apply.py --check
sudo python3 linux/system/apply.py --apply
# activation happens in 3-post_installation.sh
```

`--apply` must run as root. `--plan`, `--diff`, and `--check` can run as your
user, but need root to read root-only targets such as `/etc/sudoers.d`.
Changed files are backed up under `/var/backups/configuration/<timestamp>/`
with their original directory layout before the first write, so a failed
backup cannot leave the manifest partially applied.

`--filter REGEX` limits `--plan`, `--diff`, `--check`, and `--apply` to entries
whose destination matches the regex; `--exclude REGEX` skips matches. Both are
repeatable; `1-pre_installation.sh` filters `/etc/pacman.conf` and
`/etc/makepkg.conf.d/`, and `setup.sh --dry-run` excludes them from the final
full diff. Diffs are colored on a terminal by default; use `--color=always` or
`--color=never` to override.

It patches `pacman.conf`/`faillock.conf`, installs makepkg drop-ins, greetd
config, keyd, sudoers, xkb, `dbg.h`, and SysRq settings. OOM/sysctl tuning is
handled by `4-memory.sh`. The repo keeps no full-file copies of
`pacman.conf`, `makepkg.conf`, or `faillock.conf`; the live files are patched
or receive drop-ins.

Timeshift is configured from the current root/LUKS UUIDs:

```bash
sudo bash linux/system/timeshift.sh --dry-run
sudo bash linux/system/timeshift.sh --yes
```

It writes `/etc/timeshift/timeshift.json`; create the first snapshot with
`sudo timeshift --create --comments initial`. Home is intentionally not
included in snapshots.

## niri and DMS

niri owns the entire keymap. All keybinds live in
`~/.config/niri/binds.kdl`, which `config.kdl` includes. `dms/binds.kdl` is
intentionally not included:
DMS still provides the bar, launcher, clipboard, notifications, and other
services, but its generated keybinds are ignored. DMS actions are curated in
the niri config under `Mod+Alt`:

- `Mod+Alt+V` clipboard history
- `Mod+Alt+Space` launcher
- `Mod+Alt+N` notifications
- `Mod+Alt+M` process list
- `Mod+Alt+S` settings
- `Mod+Alt+W` wallpaper
- `Mod+Alt+L` lock
- `Mod+Alt+P` power menu
- `Mod+Alt+R` rename workspace
- `Mod+Alt+E` notepad
- `Mod+Alt+Shift+W` window rules

DMS still generates `~/.config/niri/dms/{colors,alttab,outputs,cursor}.kdl`.
Those are included with `optional=true`, so niri starts even before DMS has
deployed them. On a fresh install `3-post_installation.sh` runs `dms setup`
for missing fragments only.

`Mod+D` opens the niri overview. Typing there opens the DMS launcher because
DMS watches the overview state and uses `niriOverviewOverlayEnabled` plus
`niriOverviewLauncherStyle` (both default to enabled/full). Those are DMS
settings, not niri bindings. Do not use `dms keybinds` to change shortcuts: it
writes `dms/binds.kdl`, which this config does not load. Edit the niri config
instead.

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
