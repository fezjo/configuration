# wlvncc buffer-pacing patch

## Symptom

Periodic stderr output and a simultaneous visible stutter:

```
Oops, back-buffer is still attached.
```

wlvncc cycles three buffers. If the compositor has not released the next
buffer yet, the unpatched client still re-attaches it.

## Change

`buffer-pacing.patch`:

- Picks the next buffer that is **not** attached.
- Applies each update's damage to all three buffers so a skipped buffer
  catches up when it is released.
- Drops the frame instead of re-attaching a busy buffer when all three are
  held.
- Uploads texture damage from the target buffer's accumulated damage.

## Build

```sh
git clone https://github.com/any1/aml.git
git clone https://github.com/any1/wlvncc.git
cd wlvncc
mkdir -p subprojects
ln -s ../../aml subprojects/aml
patch -p1 < /path/to/remote/client/wlvncc/buffer-pacing.patch
meson setup build --prefix="$HOME/.local" --buildtype=release
ninja -C build
ninja -C build install
```

Result: `~/.local/bin/wlvncc`. Keep a copy of the original if the distro also
installs a client:

```sh
cp ~/.local/bin/wlvncc ~/.local/bin/wlvncc.patched
```

Runtime dependencies: `aml`, `libwayland`, `libxkbcommon`, `pixman`.
Build dependencies: `meson`, `ninja`, `pkg-config`, `wayland-protocols`.
