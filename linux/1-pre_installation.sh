#!/bin/bash
set -euo pipefail

CONF_DIR="/etc/makepkg.conf.d"
CONF_FILE="$CONF_DIR/optimize.conf"
TMP_FILE="/tmp/makepkg-optimize.conf"

# -----------------------------
# Build desired config content
# -----------------------------
cat <<'EOF' > "$TMP_FILE"
# makepkg optimization overrides

# Use all CPU cores dynamically
MAKEFLAGS="-j$(nproc)"

# Use mold linker for faster linking (C/C++)
LDFLAGS="$LDFLAGS -fuse-ld=mold"

# Use mold for Rust builds as well
RUSTFLAGS="$RUSTFLAGS -C link-arg=-fuse-ld=mold"

# Disable compression for faster packaging
PKGEXT=".pkg.tar"
SRCEXT=".src.tar"
EOF

# -----------------------------
# Apply makepkg drop-in safely
# -----------------------------
sudo install -d "$CONF_DIR"

if [[ -f "$CONF_FILE" ]]; then
    if ! diff -q "$TMP_FILE" "$CONF_FILE" >/dev/null; then
        echo "Warning: $CONF_FILE was modified. Updating it."
        sudo cp "$TMP_FILE" "$CONF_FILE"
    fi
else
    sudo cp "$TMP_FILE" "$CONF_FILE"
fi

# -----------------------------
# pacman tweaks
# -----------------------------
# Enable color
sudo sed -i 's/^#Color/Color/' /etc/pacman.conf

# -----------------------------
# Chaotic AUR setup
# -----------------------------
if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf; then
    sudo pacman-key --init
    sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    sudo pacman-key --lsign-key 3056513887B78AEB

    # Bootstrap the repo before adding it to pacman.conf.
    sudo pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'

    printf '\n[chaotic-aur]\nInclude = /etc/pacman.d/chaotic-mirrorlist\n' \
        | sudo tee -a /etc/pacman.conf >/dev/null
fi

sudo pacman -Syu --needed --noconfirm

# -----------------------------
# Install essentials
# -----------------------------
sudo pacman -S --needed --noconfirm base-devel git mold rustup
rustup default stable

sudo pacman -S --needed --noconfirm fish helix htop ghostty

if ! command -v yay >/dev/null 2>&1; then
    tmpdir="$(mktemp -d)"

    (
        cd "$tmpdir"
        git clone https://aur.archlinux.org/yay-bin.git
        cd yay-bin
        makepkg -si --noconfirm
    )

    rm -rf "$tmpdir"
fi

yay -S --needed --noconfirm  zen-browser-bin

echo "Done. Optimized makepkg config applied."
