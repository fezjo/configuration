# Client changes (anna)

## Packages

- `moonlight-qt` — Moonlight 6.2.0
- `wl-clipboard` — `wl-copy`/`wl-paste`, used for clipboard sync
- `wlvncc` — Wayland VNC client (build locally with the pacing patch)
- `openssh`, `openbsd-netcat` — tunnel and reachability checks
- `fuzzel` / a desktop environment — only for launching the shortcut

## 1. Install the launcher and shortcut

```sh
cd client
./install.sh
```

This installs:

| Source | Destination |
|---|---|
| `bin/remote-desktop` | `~/.local/bin/remote-desktop` |
| `bin/clipboard-sync` | `~/.local/bin/clipboard-sync` |
| `bin/moonlight-knut` | `~/.local/bin/moonlight-knut` |
| `applications/moonlight-knut.desktop` | `~/.local/share/applications/moonlight-knut.desktop` |

`remote-desktop` and `clipboard-sync` are also tracked by chezmoi:

```sh
chezmoi add ~/.local/bin/remote-desktop ~/.local/bin/clipboard-sync
chezmoi status
```

Add `moonlight-knut` and its desktop entry the same way if you want them
managed too.

## 2. Build the patched wlvncc

The stock client prints `Oops, back-buffer is still attached.` and visibly
stutters when the compositor holds a buffer. The patch skips attached buffers,
accumulates damage, and drops frames only when all three are busy.

See `wlvncc/README.md`. Install to a directory in `PATH`:

```sh
ninja -C build install             # installs to ~/.local/bin
```

Dependencies: `aml`, `libwayland`, `libxkbcommon`, `pixman`, `meson`,
`ninja`, `wayland-protocols`.

## 3. SSH host alias

Add `ssh/config.snippet` to `~/.ssh/config`:

```sshconfig
Host knut-lan
    HostName 192.168.1.100
    User fezjo
```

`remote-desktop` uses the SSH destination for `setup`/`teardown`, and resolves
its `HostName` for Moonlight. `knut-lan` is the wired address; `knut` (the
hostname) and Tailscale continue to work for VNC tunneling.

If you also have a stale `knut-local`, point it at `192.168.1.100`:

```sshconfig
Host knut-local
    HostName 192.168.1.100
    User fezjo
```

Verify:

```sh
ssh -G knut-lan | grep -E '^(hostname|user) '
ssh knut-lan true
```

## 4. Pair Moonlight with Sunshine (once)

1. Make sure Sunshine is running on the server:

   ```sh
   remote-desktop setup sunshine knut-lan
   ```

2. Start Moonlight:

   ```sh
   moonlight
   ```

3. Add the host `192.168.1.100` (or select it if already listed).
4. Moonlight shows a 4-digit PIN.
5. Open `https://192.168.1.100:47990`, sign in, and enter the PIN.
6. Quit Moonlight.

Pairing is stored in `~/.config/Moonlight Game Streaming Project/`. The
launcher checks it with:

```sh
moonlight list 192.168.1.100
```

If that command fails, pairing is missing or the server is not reachable.

## 5. Usage

```sh
remote-desktop setup    sunshine knut-lan
remote-desktop connect  sunshine knut-lan --quality medium
remote-desktop teardown sunshine knut-lan
```

`connect` without `--quality` prompts:

```
Quality:
  1) low     720p30, 5 Mbps
  2) medium  1080p60, 20 Mbps
  3) high    1080p60, 40 Mbps
Choose [2]:
```

Targets:

```sh
remote-desktop setup    umbriel knut
remote-desktop connect  umbriel knut

remote-desktop setup    niri knut
remote-desktop connect  niri knut
```

The `moonlight-knut` shortcut and the **Sunshine (knut 1080p60)** desktop entry
run:

```sh
remote-desktop connect sunshine knut-lan --quality medium
```

## 6. Clipboard sharing

`connect sunshine` starts a two-way text clipboard sync over SSH for the
duration of the Moonlight stream. Copying text on either machine makes it
available on the other within a fraction of a second. The sync starts before
Moonlight and stops when Moonlight exits or `teardown` runs.

Both machines need `wl-clipboard`. The remote side uses the main niri session,
detected through `WAYLAND_DISPLAY` or the running systemd user session.

Manage it manually when needed:

```sh
clipboard-sync start  knut-lan
clipboard-sync status knut-lan
clipboard-sync stop   knut-lan
```

Run `clipboard-sync run knut-lan` in the foreground to see errors. State and
logs live under `$XDG_RUNTIME_DIR/remote-desktop/clipboard/`.

Only `text/plain` is synchronized. Images, copied files, and rich text are
ignored. Use `--no-clipboard` to disable the bridge for one session:

```sh
remote-desktop connect sunshine knut-lan --no-clipboard
```

Moonlight's own `Ctrl+Alt+Shift+V` still works; it types the client clipboard
into the host. With the bridge running, normal copy/paste on knut is enough.

## 7. What the launcher does on the client

For VNC:

- Allocates a free local port in `15900-15999`.
- Opens `ssh -N -L <local>:127.0.0.1:<5900|5902> <host>`.
- Launches `wlvncc 127.0.0.1 <local>`.
- Keeps state under `$XDG_RUNTIME_DIR/remote-desktop/`.

For Sunshine:

- Resolves the SSH host to its `HostName` (`192.168.1.100`).
- Starts `clipboard-sync` unless `--no-clipboard` is given.
- Checks port 47989 and `moonlight list`.
- Runs `moonlight stream <host> Desktop` with the quality flags.
- Stops `clipboard-sync` when Moonlight exits.

## Troubleshooting

| Symptom | Fix |
|---|---|
| `moonlight not found` | install `moonlight-qt`, or set `MOONLIGHT_BIN` |
| `Moonlight is not paired` | pair once (section 4) |
| `Sunshine is not reachable` | run `remote-desktop setup sunshine <host>`; check server firewall |
| `clipboard sync failed to start` | run `clipboard-sync run <host>` to see the error; check the log under `$XDG_RUNTIME_DIR/remote-desktop/clipboard/` |
| No clipboard sync during the stream | `--no-clipboard` was passed, or `clipboard-sync` is not in `PATH`/`~/.local/bin` |
| VNC tunnel fails | `ssh <host> true`; check `wayvnc` is listening on `127.0.0.1` |
| `wlvncc` stutters | use the patched build, check `command -v wlvncc` |
| niri `Mod+...` does nothing over VNC | expected; use `sunshine` |
