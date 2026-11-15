# configuration

Personal configuration for Arch Linux, macOS, and Windows.

## Machines

| Host | Form | CPU | Compositor | Shell | Role |
|---|---|---|---|---|---|
| `anna` | laptop | AMD 4750U | Umbriel | Noctalia | remote-desktop client |
| `knut` | desktop | AMD 7950X | niri | DMS | remote-desktop server |

Machine profiles live in `linux/chezmoi/.chezmoidata/hosts.toml`. They select
the compositor, shell, roles, and output layout. Form factor and CPU vendor are
detected automatically when not set in the profile.

Compositors and shells are independent. Both `niri`/`DMS` and
`Umbriel`/Noctalia remain in the repo; each machine deploys only what it
selects.

## Layout

```text
linux/
  chezmoi/                    home-directory source of truth
    .chezmoidata/hosts.toml   machine profiles
    .chezmoiignore            per-host file filtering
  packages/                   layered package lists
    common.md
    install-only.md
    form/{laptop,desktop}.md
    cpu/{amd,intel}.md
    compositor/{niri,umbriel}.md
    shell/{dms,noctalia}.md
    role/{remote-client,remote-server}.md
    host/knut.md
  system/
    apply.py                  layered system file manifest runner
    hostinfo.py               profile and layer resolver
    manifest.toml             common system files and edits
    manifests/                form, compositor, shell, role layers
  hooks/                      post-install hooks per layer
  archinstall-no_disk_user.json
  1-pre_installation.sh
  2-install_packages.sh
  3-post_installation.sh
  setup.sh
  remote/                     remote-desktop client/server setup
  root/                       system files deployed by system/apply.py
archive/                      unused configurations, not deployed
macos/                        separate setup
windows/                      separate setup notes
```

## Setup

New machine:

1. Boot the Arch ISO and run `archinstall --config linux/archinstall-no_disk_user.json`.
   Edit the disk, user, hostname, and packages interactively. New installs use
   btrfs + LUKS + systemd-boot + UKI + mkinitcpio.
2. First boot: clone this repository, make sure the age identity exists at
   `~/.ssh/ssh_fezjo`, and run:

   ```bash
   bash linux/setup.sh install
   ```

Existing machine:

```bash
bash linux/setup.sh sync
```

`sync` updates packages, system files, dotfiles, and host hooks without
installing kernels, changing initramfs tooling, or touching boot entries. It
also switches the display manager to greetd; a reboot is needed to leave
lightdm.

Preview either mode:

```bash
bash linux/setup.sh plan
bash linux/setup.sh --dry-run
```

Optional overrides:

```bash
bash linux/setup.sh sync --host knut --form desktop --cpu amd
```

The host profile must match the current hostname for a real run. `--host`,
`--form`, and `--cpu` are useful for previews and for overriding detection.

Each stage also supports `--dry-run`:

```bash
bash linux/1-pre_installation.sh --dry-run
bash linux/2-install_packages.sh --dry-run --host knut --mode sync
sudo python3 linux/system/apply.py --diff --host knut
bash linux/3-post_installation.sh --dry-run --host knut
```

`1-pre_installation.sh` installs `reflector`, selects the 20 most recently
synced HTTPS mirrors in Slovakia, Czechia, Austria, and Germany by download
rate, installs the bootstrap tools, and applies the pacman and makepkg entries
from the common manifest. Override `REFLECTOR_COUNTRIES` to change the country
list; set it to an empty value to disable the country filter.

## Package layers

`2-install_packages.sh` merges, in order:

```text
common
install-only (install mode only)
form/<detected>
cpu/<detected>
compositor/<selected>
shell/<selected>
role/<selected roles>
host/<hostname>
```

A later layer can add `+package` or remove `-package` from the resolved list.
Removal only affects the list; it never uninstalls anything.

`install-only.md` contains kernels, initramfs tools, and boot packages. `sync`
does not load it, which is what keeps an existing machine's boot setup intact.

## System manifests

`system/apply.py` merges the same layers and then applies the resulting file
manifest:

```bash
sudo python3 linux/system/apply.py --plan --host knut
sudo python3 linux/system/apply.py --diff --host knut
sudo python3 linux/system/apply.py --apply --yes --host knut
```

Common entries cover pacman, makepkg, keyd, xkb, sudoers, `dbg.h`, and SysRq.
Form layers cover logind power-button behavior. Compositor layers deploy the
greetd session config and greeter files.

`--filter REGEX` and `--exclude REGEX` are repeatable. Changed files are backed
up under `/var/backups/configuration/<timestamp>/` before the first write.

`hostinfo.py` is the shared resolver:

```bash
python3 linux/system/hostinfo.py --host knut shell-env
python3 linux/system/hostinfo.py --host knut packages --mode sync
python3 linux/system/hostinfo.py --host knut manifests
```

## greetd

Every machine uses greetd:

- niri: `agreety --cmd niri-session`
- Umbriel: `agreety --cmd start-umbriel`

`3-post_installation.sh` enables greetd and disables lightdm without stopping
the running session. Reboot to switch.

## niri

`niri/config.kdl` includes:

- `outputs.kdl`, generated from `hosts.toml`
- `binds.kdl`, compositor-level keybinds
- `shell.kdl`, generated from the shell profile; it contains that shell's
  keybinds and startup behavior. The per-shell source lives next to it in
  `dot_config/niri/shells/*.kdl`; that directory is ignored as a deployment
  target.

DMS starts through `systemd/user/niri.service.d/dms.conf` when niri + DMS is
selected. DMS-owned colors/alttab/cursor fragments are seeded only when
missing. DMS does not own the output layout.

## Umbriel and Noctalia

`umbriel/config.toml` includes generated `shell.toml` and `outputs.toml`.
`shell.toml` selects common plus shell-specific keybinds and sets the shell
autostart. Noctalia uses the tracked Noctalia config; DMS uses `dms run` under
Umbriel.

The `umbriel-lid` helper is deployed only for Umbriel hosts.

## Displays

Outputs are matched by connector name or by `manufacturer model serial`.
Disconnected outputs are ignored, so one host can define layouts for multiple
physical locations.

`knut` currently defines the living-room TV:

```text
Samsung Electric Company SAMSUNG 0x00000001
1920x1080@60, scale 1, position 0,0
```

The office monitors are not filled in yet. While in the office, run
`niri msg outputs` and add the monitor identities to
`linux/chezmoi/.chezmoidata/hosts.toml` with the old modes:

- left: `2560x1080@200` at `0,0`
- right: `2560x1440@165` at `2560,0`

## DMS settings

DMS 2.1 supports `config.d` drop-ins. The tracked policy lives in:

```text
~/.config/dms/config.d/00-common.json
~/.config/dms/config.d/05-host-specific.json   (when needed)
```

`~/.config/dms/settings.json` is not managed by chezmoi. DMS keeps local/UI
overrides there, and `config.d` values take precedence over it.

## Aliases

`~/.config/shell/aliases.sh` is the single alias source for bash and zsh.
Fish loads the same file through `basrs`:

```fish
basrs source $HOME/.config/shell/aliases.sh | source
```

This is why `dyff` and the other aliases work in fish without a duplicate
`aliases.fish`.

## Secrets

`.ssh/config` and `.ssh/known_hosts` are stored as age-encrypted chezmoi files.
The age recipient is the public key from `~/.ssh/ssh_fezjo.pub`; decryption
uses the private key `~/.ssh/ssh_fezjo`. Install `age` on new machines and copy
the key from a trusted backup; it is not stored here.

The deployed chezmoi config expects the repository at `~/src/configuration`;
change `sourceDir` if you clone elsewhere.

`~/.config/Code/User/settings.json` is ignored because the live file is
application-managed and may contain extension API keys. Do not run a blanket
`chezmoi add ~/.config`.

## knut migration notes

The live `knut` install predates this layout. One-time cleanup:

1. Confirm `linux`/`linux-lts` boot entries work.
2. Remove `linux-git` and its stale kernel/loader entries. It was only a
   local kernel-compilation test.
3. Rename `~/.ssh/id_ed25519_fezjo` to `~/.ssh/ssh_fezjo` (and the `.pub`).
   The key material is the same as the repo's age recipient.
4. Run `bash linux/setup.sh plan`, then `bash linux/setup.sh sync`.
5. Reboot to leave lightdm for greetd.

The old `eirik` SSH entries are intentionally dropped; the shared encrypted
SSH files are authoritative.

## Environment

`~/.config/environment.d/*.conf` is the single source for XDG directories and
tool-specific paths. It is read by the systemd user manager and loaded by
`.profile`, bash, zsh and fish for TTY/SSH sessions.

`~/.config/shell/env.sh` is the shell loader. Do not duplicate XDG/tool paths in
individual shell files.

## Checks

```bash
make check
```

This validates shell syntax, fish syntax, JSON, Python syntax, TOML, and the
niri, Umbriel, and Noctalia configs when those tools are installed. It also
checks that `basrs` exposes the `dyff` alias when `basrs` is available.

## Remote desktop

`linux/remote/` contains the reproducible server (`knut`) and client (`anna`)
setup. The `remote-server` and `remote-client` roles run their installers from
`3-post_installation.sh`.

## Archive

`archive/` contains unused desktop, shell, editor, and tool configurations plus
the scripts tied to them. It is not deployed.

`macos/` and `windows/` remain separate setups.
