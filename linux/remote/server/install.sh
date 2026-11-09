#!/usr/bin/env bash
# Install the server-side files for remote-desktop on this machine.
# Run as the desktop user (not root). Use sudo only for sudo firewall.sh.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bindir=${BINDIR:-$HOME/.local/bin}
unitdir=${UNITDIR:-$HOME/.config/systemd/user}
appdir=${APPDIR:-$HOME/.local/share/applications}

install -d "$bindir" "$unitdir" "$appdir" \
    "$HOME/.config/umbriel" "$HOME/.config/sunshine"

install -m755 "$here/bin/niri-mod-alt.sh"          "$bindir/niri-mod-alt.sh"
install -m755 "$here/bin/sunshine-mod-watch.sh"    "$bindir/sunshine-mod-watch.sh"
install -m755 "$here/bin/zen-umbriel"              "$bindir/zen-umbriel"
install -m755 "$here/umbriel/remote-output.sh"     "$HOME/.config/umbriel/remote-output.sh"

install -m644 "$here/systemd/user/umbriel-remote.service" \
    "$here/systemd/user/wayvnc-umbriel.service" \
    "$here/systemd/user/wayvnc-niri.service" \
    "$here/systemd/user/sunshine-mod-watch.service" \
    "$unitdir/"

# Desktop entry: substitute the real home directory.
sed "s|@HOME@|$HOME|g" \
    "$here/applications/zen-umbriel.desktop" > "$appdir/zen-umbriel.desktop"

# Sunshine config: do not overwrite an existing file.
if [ ! -e "$HOME/.config/sunshine/sunshine.conf" ]; then
    install -m644 "$here/sunshine/sunshine.conf" \
        "$HOME/.config/sunshine/sunshine.conf"
else
    echo "kept existing $HOME/.config/sunshine/sunshine.conf"
fi

# Umbriel config: seed from the package default, then add the two changes.
cfg="$HOME/.config/umbriel/config.toml"
if [ ! -e "$cfg" ]; then
    if [ -r /usr/share/umbriel/config.toml ]; then
        cp /usr/share/umbriel/config.toml "$cfg"
        tmp=$(mktemp)
        awk -v home="$HOME" -v auto=0 -v binds=0 '
            /^# autostart = / && !auto {
                printf "autostart = [\"%s/.config/umbriel/remote-output.sh\"]\n", home
                auto = 1
                next
            }
            /^\[keybinds\]$/ && !binds {
                print
                print "\"Mod+D\" = \"spawn fuzzel\""
                printf "\"Mod+B\" = \"spawn %s/.local/bin/zen-umbriel\"\n", home
                binds = 1
                next
            }
            { print }
        ' "$cfg" > "$tmp"
        mv "$tmp" "$cfg"
    else
        echo "warning: /usr/share/umbriel/config.toml not found" >&2
        echo "         merge $here/umbriel/config.toml.snippet manually" >&2
    fi
else
    if ! grep -q 'remote-output.sh' "$cfg"; then
        echo "warning: $cfg exists but does not start remote-output.sh" >&2
        echo "         merge $here/umbriel/config.toml.snippet manually" >&2
    fi
fi

systemctl --user daemon-reload
systemctl --user enable umbriel-remote.service wayvnc-umbriel.service \
    sunshine-mod-watch.service
systemctl --user start  umbriel-remote.service wayvnc-umbriel.service \
    sunshine-mod-watch.service

cat <<EOF

Installed user files.

Next steps:
  1. Build the patched WayVNC (see server/wayvnc/README.md), then:
       install -m755 build/wayvnc "\$HOME/.local/bin/wayvnc-niri"
  2. Allow Sunshine through the firewall:
       sudo $here/firewall.sh
  3. Optional RustDesk drop-in:
       sudo install -Dm644 "$here/systemd/system/rustdesk.service.d/wayland.conf" \\
         /etc/systemd/system/rustdesk.service.d/wayland.conf
       sudo systemctl daemon-reload

wayvnc-niri.service and Sunshine are intentionally not enabled at boot;
remote-desktop starts them on demand.
EOF
