#!/usr/bin/env bash
# Install the client-side files for remote-desktop on this machine.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
bindir=${BINDIR:-$HOME/.local/bin}
appdir=${APPDIR:-$HOME/.local/share/applications}

. "$here/../lib.sh"

INSTALL_PACKAGES=1

usage() {
    cat <<'EOF'
usage: install.sh [--no-packages]

  --no-packages   install the helper scripts but skip packages.txt
EOF
}

while (( $# )); do
    case "$1" in
        --no-packages) INSTALL_PACKAGES=0 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

if (( INSTALL_PACKAGES )); then
    install_packages "$here/packages.txt"
fi

install -d "$bindir" "$appdir"

install -m755 "$here/bin/remote-desktop" "$bindir/remote-desktop"
install -m755 "$here/bin/clipboard-sync" "$bindir/clipboard-sync"

sed "s|@HOME@|$HOME|g" "$here/bin/moonlight-knut" \
    > "$bindir/moonlight-knut"
chmod 755 "$bindir/moonlight-knut"

sed "s|@HOME@|$HOME|g" "$here/applications/moonlight-knut.desktop" \
    > "$appdir/moonlight-knut.desktop"

echo "installed:"
echo "  $bindir/remote-desktop"
echo "  $bindir/clipboard-sync"
echo "  $bindir/moonlight-knut"
echo "  $appdir/moonlight-knut.desktop"

missing=0
for c in moonlight wlvncc ssh nc wl-copy wl-paste flock; do
    if ! command -v "$c" >/dev/null 2>&1; then
        echo "warning: '$c' is not in PATH" >&2
        missing=1
    fi
done

cat <<EOF

Next steps:
  1. Build the patched wlvncc (client/wlvncc/README.md).
  2. Add the SSH alias from client/ssh/config.snippet to ~/.ssh/config.
  3. Pair Moonlight once: run 'moonlight', add the server, enter its PIN
     in the Sunshine web UI at https://<server>:47990.
EOF

if [ "$missing" -ne 0 ]; then
    echo
    echo "Install the missing dependencies before connecting." >&2
fi
