# Server changes (knut)

All commands run on `knut` as the desktop user unless marked `sudo`.

## Packages

`packages.txt` lists the explicit packages. Summary:

| Package | Purpose |
|---|---|
| `niri` | default compositor |
| `umbriel-git` | headless remote compositor |
| `xdg-desktop-portal-umbriel-git` | portals for the Umbriel session |
| `xdg-desktop-portal`, `xdg-desktop-portal-gtk` | screen sharing / file dialogs |
| `wl-clipboard` | clipboard sync with the Moonlight client |
| `wayvnc` | VNC server for Umbriel (packaged build) |
| `sunshine-bin` (AUR) | Sunshine game stream host |
| `rustdesk-bin` (optional) | installed, currently unused |

`sunshine-bin` provides `app-dev.lizardbyte.app.Sunshine.service` in
`/usr/lib/systemd/user/`.

## 1. Umbriel headless session

Files:

- `systemd/user/umbriel-remote.service`
- `umbriel/remote-output.sh`
- `umbriel/config.toml.snippet`

The unit runs Umbriel with a headless wlroots backend in its own runtime
directory:

```ini
Environment=XDG_RUNTIME_DIR=/run/user/%U/umbriel-remote
Environment=WAYLAND_DISPLAY=umbriel-remote
Environment=WLR_BACKENDS=headless
Environment=WLR_HEADLESS_OUTPUTS=0
Environment=WLR_RENDERER_ALLOW_SOFTWARE=1
ExecStart=/usr/bin/umbriel
```

`remote-output.sh` runs at Umbriel startup (via `[general] autostart`) and
creates a virtual output:

```sh
/usr/bin/umbriel output-create remote 1920x1080@60
```

Add the snippet to `~/.config/umbriel/config.toml`:

```toml
[general]
autostart = ["/home/fezjo/.config/umbriel/remote-output.sh"]

[input.keyboard]
numlock_toggle = true

[keybinds]
"Mod+D" = "spawn fuzzel"
"Mod+B" = "spawn /home/fezjo/.local/bin/zen-umbriel"
```

`config.toml.snippet` uses `@HOME@`; `install.sh` substitutes the real path
when it creates the file. The packaged default config is otherwise unchanged.

The separate Zen profile avoids Zen forwarding the URL to the already-running
niri instance:

- `bin/zen-umbriel` launches `zen-browser --no-remote --new-instance
  --profile "$HOME/.zen-umbriel"` inside the Umbriel session.
- Optional desktop entry: `~/.local/share/applications/zen-umbriel.desktop`.

## 2. WayVNC for Umbriel (port 5900)

File: `systemd/user/wayvnc-umbriel.service`

```ini
Environment=XDG_RUNTIME_DIR=/run/user/%U/umbriel-remote
Environment=WAYLAND_DISPLAY=wayland-0
Environment=UMBRIEL_SOCKET=/run/user/%U/umbriel-remote/umbriel-wayland-0.sock
ExecStartPre=/bin/sh -c '... umbriel outputs | grep -q remote ...'
ExecStart=/usr/bin/wayvnc -o remote -r -f 60 -g 127.0.0.1:5900
```

It binds to `127.0.0.1` and is bound to the Umbriel session
(`BindsTo=umbriel-remote.service`). It uses the packaged `/usr/bin/wayvnc`.

## 3. WayVNC for niri (port 5902)

File: `systemd/user/wayvnc-niri.service`

```ini
Environment=XDG_RUNTIME_DIR=/run/user/%U
Environment=WAYLAND_DISPLAY=wayland-1
ExecStart=%h/.local/bin/wayvnc-niri -r -f 60 -g 127.0.0.1:5902
```

This uses a locally built WayVNC with the linear DMA-BUF patch. Without the
patch, VAAPI H.264 frames from niri decode as black.

Build it once, see `wayvnc/README.md`:

```sh
git clone https://github.com/any1/wayvnc
cd wayvnc
git checkout v0.10.2
patch -p1 < /path/to/remote/server/wayvnc/linear-dmabuf.patch
meson setup build --buildtype=release
ninja -C build
install -m755 build/wayvnc "$HOME/.local/bin/wayvnc-niri"
```

The unit is **not enabled**. Start it with `remote-desktop setup niri knut`
or `systemctl --user start wayvnc-niri.service`.

## 4. Sunshine (port 47989)

Files:

- `sunshine/sunshine.conf`
- systemd user unit from the `sunshine-bin` package

`~/.config/sunshine/sunshine.conf`:

```ini
capture = wlr
encoder = vaapi
min_log_level = debug
```

- `capture = wlr` uses the wlroots screencopy path on Wayland.
- `encoder = vaapi` selects the AMD VAAPI encoder.
- `min_log_level = debug` is needed by the Mod-key watcher, which matches
  `CLIENT CONNECTED` / `CLIENT DISCONNECTED` log lines.

Start/stop:

```sh
systemctl --user start app-dev.lizardbyte.app.Sunshine.service
systemctl --user stop  app-dev.lizardbyte.app.Sunshine.service
```

The unit is **not enabled**; `remote-desktop setup sunshine` starts it.

First-time setup:

1. Open `https://<host>:47990` and set credentials with
   `sunshine --creds` (the web UI defaults are temporary).
2. Pair Moonlight: start Moonlight on the client, select `knut`, and enter the
   PIN in the Sunshine web UI under **PIN**.
3. `apps.json` from the package already provides `Desktop`, `Low Res Desktop`
   and `Steam Big Picture`. The launcher streams `Desktop`.

The client's `clipboard-sync` helper uses `wl-copy`/`wl-paste` over SSH against
the niri session. It needs `wl-clipboard` here; no Sunshine setting is involved.
Only text is synced.

Do not copy `sunshine_state.json` or `credentials/` between machines; they are
per-install secrets/pairing state.

## 5. Mod-key watcher

Files:

- `systemd/user/sunshine-mod-watch.service`
- `bin/sunshine-mod-watch.sh`
- `bin/niri-mod-alt.sh`

```ini
Environment=SUNSHINE_LOG=%h/.config/sunshine/sunshine.log
ExecStart=%h/.local/bin/sunshine-mod-watch.sh
Restart=always
```

`sunshine-mod-watch.sh` tails the Sunshine log:

- `CLIENT CONNECTED` → `niri-mod-alt.sh on`
- `CLIENT DISCONNECTED` or `Session ended` → `niri-mod-alt.sh off`

`niri-mod-alt.sh on` inserts `mod-key "Alt"` after the first `input {` line in
`~/.config/niri/config.kdl` and reloads niri through its IPC socket. `off`
removes that line and reloads again.

Sunshine's own `prep-cmd` "undo" is not reliably run on disconnect, which is
why an external log watcher is used.

## 6. RustDesk (optional, currently broken)

RustDesk 1.5.1 is installed and enabled, but Wayland capture fails with
`Failed to get capturer display info`. The drop-in is kept for completeness:

`/etc/systemd/system/rustdesk.service.d/wayland.conf`:

```ini
[Service]
Environment=RUSTDESK_FORCED_DISPLAY_SERVER=wayland
Environment=XDG_SESSION_TYPE=wayland
```

Install with:

```sh
sudo install -Dm644 systemd/system/rustdesk.service.d/wayland.conf \
    /etc/systemd/system/rustdesk.service.d/wayland.conf
sudo systemctl daemon-reload
```

RustDesk is not used by `remote-desktop`.

## 7. Firewall

`firewalld` must allow Sunshine:

```sh
sudo ./firewall.sh
```

Permanent ports:

- TCP `47984-47990`, `48010`
- UDP `47998-48002`, `48010`

No VNC port is opened. WayVNC listens on `127.0.0.1` and is reached through
SSH.

## 8. Install order

```sh
./install.sh

# build patched WayVNC (section 3)
install -m755 build/wayvnc "$HOME/.local/bin/wayvnc-niri"

sudo ./firewall.sh

systemctl --user daemon-reload
systemctl --user enable --now umbriel-remote.service
systemctl --user enable --now wayvnc-umbriel.service
systemctl --user enable --now sunshine-mod-watch.service

# on demand only
systemctl --user start wayvnc-niri.service
systemctl --user start app-dev.lizardbyte.app.Sunshine.service
```

`install.sh` does not overwrite an existing `~/.config/umbriel/config.toml`
or `~/.config/sunshine/sunshine.conf`; it prints what still needs to be added.

## Troubleshooting

| Symptom | Check |
|---|---|
| VNC not listening | `systemctl --user status wayvnc-umbriel wayvnc-niri` |
| Black H.264 over niri VNC | patched `~/.local/bin/wayvnc-niri` is in use |
| `Mod+...` does nothing over VNC | expected on niri 26.04; use Sunshine |
| Sunshine not reachable | `ss -ltn \| grep 47989`, `firewall-cmd --list-ports` |
| Clipboard sync fails | `wl-paste -n` works over SSH with `WAYLAND_DISPLAY` set; `wl-clipboard` is installed |
| Mod key stays Alt | `niri-mod-alt.sh off`, check watcher log |
| niri shortcuts dead in Moonlight | `sunshine-mod-watch.service` active, niri reloaded |
