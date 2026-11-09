# Remote desktop (Umbriel, niri, Sunshine)

Reproducible configuration for remote access to `knut` from `anna`.

Three transports are supported:

| Target | Server | Client | Transport | Port |
|---|---|---|---|---|
| `umbriel` | Umbriel headless session + WayVNC | wlvncc | SSH tunnel + VNC | 5900 (localhost) |
| `niri` | niri + patched WayVNC | wlvncc | SSH tunnel + VNC | 5902 (localhost) |
| `sunshine` | Sunshine streaming niri | Moonlight | direct LAN/WAN | 47989, 47984-47990, 48010 |

niri stays the default compositor on the physical machine. Umbriel runs in a
separate headless session and is only started for remote use.

## Why Sunshine for niri

niri 26.04 drops virtual-keyboard modifier state before matching compositor
bindings (niri issues [#3595](https://github.com/YaLTeR/niri/issues/3595) and
[#4685](https://github.com/YaLTeR/niri/issues/4685)). A VNC client can type
into applications, but `Mod+...` bindings never fire. WayVNC cannot work
around this.

Sunshine injects input through uinput, so niri shortcuts work. Umbriel is a
wlroots compositor and handles VNC modifiers correctly, so WayVNC remains the
right choice there.

## Layout

```
remote/
├── README.md                  this file
├── server/                    changes on knut
│   ├── README.md
│   ├── packages.txt
│   ├── install.sh
│   ├── firewall.sh
│   ├── bin/                   helper scripts → ~/.local/bin
│   ├── systemd/user/          systemd user units
│   ├── systemd/system/        system-wide drop-ins
│   ├── umbriel/               headless-session config
│   ├── sunshine/              sunshine.conf
│   └── wayvnc/                linear DMA-BUF patch + build notes
└── client/                    changes on anna
    ├── README.md
    ├── install.sh
    ├── bin/                   remote-desktop, clipboard-sync, moonlight-knut
    ├── applications/          desktop entry
    ├── ssh/                   SSH host alias snippet
    └── wlvncc/                buffer pacing patch + build notes
```

## Server reproduction (knut)

```sh
cd server
./install.sh                  # user units, scripts, Umbriel config
sudo ./firewall.sh            # Sunshine ports
# build the patched WayVNC, see server/wayvnc/README.md

systemctl --user enable --now umbriel-remote.service wayvnc-umbriel.service
systemctl --user enable --now sunshine-mod-watch.service
```

`wayvnc-niri.service` and `app-dev.lizardbyte.app.Sunshine.service` are
intentionally **not** enabled at boot. `remote-desktop setup` starts them on
demand and `teardown` stops them again.

Requires `niri` 26.04 and the packages listed in `server/packages.txt`.
See `server/README.md` for the full walkthrough.

## Client reproduction (anna)

```sh
cd client
./install.sh                  # remote-desktop, moonlight-knut, desktop entry
# build the patched wlvncc, see client/wlvncc/README.md
```

Add the host alias from `client/ssh/config.snippet` to `~/.ssh/config`:

```sshconfig
Host knut-lan
    HostName 192.168.1.100
    User fezjo
```

Pair Moonlight once with Sunshine:

```sh
moonlight
```

Choose `knut`, enter the PIN shown by Moonlight in the Sunshine web UI at
`https://192.168.1.100:47990`, then quit. Pairing is stored in
`~/.config/Moonlight Game Streaming Project/`.

See `client/README.md` for details.

## Usage

```sh
remote-desktop <setup|connect|teardown> <umbriel|niri|sunshine> <host> [--quality low|medium|high]
```

Examples:

```sh
remote-desktop setup    sunshine knut-lan
remote-desktop connect  sunshine knut-lan --quality medium
remote-desktop teardown sunshine knut-lan

remote-desktop setup    umbriel knut
remote-desktop connect  umbriel knut
```

If `--quality` is omitted on `connect sunshine`, the launcher prompts when
stdin is a terminal:

```
Quality:
  1) low     720p30, 5 Mbps    (stable Wi-Fi)
  2) medium  1080p60, 20 Mbps  (wired LAN / good Wi-Fi)
  3) high    1080p60, 40 Mbps  (wired LAN)
Choose [2]:
```

VNC targets ignore the quality preset; their resolution is set on the server.

`connect sunshine` also starts a two-way text clipboard bridge over SSH for the
duration of the Moonlight stream. Use `--no-clipboard` to disable it. See
[client/README.md](client/README.md#6-clipboard-sharing) for details and
limits.

## What `remote-desktop` does

`umbriel` / `niri` (VNC):

1. `setup` starts the session unit (Umbriel only) and the WayVNC unit, then
   waits for `127.0.0.1:<port>` to listen.
2. `connect` runs `setup` if needed, opens an SSH tunnel from a free local
   port in `15900-15999`, and launches `wlvncc`.
3. `teardown` stops the WayVNC unit, stops the Umbriel session, and kills the
   local tunnel and client.

`sunshine`:

1. `setup` starts `app-dev.lizardbyte.app.Sunshine.service` and
   `sunshine-mod-watch.service`, then waits for port 47989.
2. `connect` checks reachability and pairing, starts `clipboard-sync` (unless
   `--no-clipboard`), then runs Moonlight with the selected resolution, FPS and
   bitrate. The clipboard bridge stops when Moonlight exits.
3. `teardown` stops Sunshine and the watcher, stops clipboard sync, and
   restores niri's Mod key.

## Mod key during streams

niri normally uses `Super`. While a Sunshine client is connected,
`sunshine-mod-watch.service` calls `niri-mod-alt.sh on`, which adds:

```kdl
input {
    mod-key "Alt"
}
```

and reloads niri. On disconnect it removes the line again. No permanent
`mod-key` line is kept in `~/.config/niri/config.kdl`.

This is deliberately not global: the change exists only for the duration of a
remote stream.

## Verification

```sh
# server
ssh knut 'ss -ltn | grep -E ":5900|:5902|:47989"'

# client
remote-desktop connect sunshine knut-lan --quality medium
# Moonlight statistics should show ~0 % network drops and 1 ms LAN latency
```

## Known limitations

- niri 26.04 VNC has no compositor shortcuts. Use `sunshine` for niri.
- Clipboard sync is text-only; images and copied files are not transferred.
  It also needs `wl-clipboard` on both machines and a working SSH connection.
- WayVNC listens on `127.0.0.1` only; VNC is reachable through SSH.
- Sunshine is directly reachable on the LAN and needs firewall ports.
- RustDesk is installed on `knut` but its Wayland capture fails; it is not used.
- Sunshine web UI credentials must be changed from the initial setup values
  with `sunshine --creds`.

## Files not to copy

Do not commit or copy these from `knut`:

- `~/.config/sunshine/sunshine_state.json` (pairing state)
- `~/.config/sunshine/credentials/` (web UI credentials)
- `~/.config/sunshine/sunshine.log*`
