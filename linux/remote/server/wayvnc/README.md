# WayVNC 0.10.2 + linear DMA-BUF patch

## Symptom

niri 26.04 with VAAPI H.264: Tight/shm capture works, but the H.264 stream
decodes as a black frame. wlvncc and the server look healthy.

## Cause

niri's `wlr-screencopy` advertises `XRGB8888` without a modifier list. WayVNC
lets GBM pick a driver-chosen (tiled) modifier. VAAPI/DRM-PRIME import of that
buffer produces black frames.

## Change

`linear-dmabuf.patch` makes `src/buffer.c` allocate with
`DRM_FORMAT_MOD_LINEAR` when `config->n_modifiers == 0`.

## Build

```sh
git clone https://github.com/any1/wayvnc
cd wayvnc
git checkout v0.10.2
patch -p1 < /path/to/remote/server/wayvnc/linear-dmabuf.patch
meson setup build --buildtype=release
ninja -C build
install -m755 build/wayvnc "$HOME/.local/bin/wayvnc-niri"
```

Installed binary: `~/.local/bin/wayvnc-niri`
Used by: `~/.config/systemd/user/wayvnc-niri.service` (127.0.0.1:5902)

The Umbriel service on 5900 keeps using the packaged `/usr/bin/wayvnc`.

## Known niri limitation (not fixed here)

niri 26.04 does not pass virtual-keyboard modifier state to compositor
bindings. VNC clients can type and use application shortcuts, but niri's own
`Mod+...` bindings do not fire. Tracked upstream (niri issues #3595 and #4685).
Use the `sunshine` target for working niri shortcuts.
