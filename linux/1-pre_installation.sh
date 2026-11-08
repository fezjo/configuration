#!/bin/bash
set -euo pipefail

DRY_RUN=0

usage() {
    cat <<'EOF'
usage: 1-pre_installation.sh [--dry-run]

  -n, --dry-run   show what would change without touching the system
EOF
}

while (( $# )); do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
    shift
done

run() {
    if (( DRY_RUN )); then
        printf '    [dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

warn() { printf '    warn: %s\n' "$*" >&2; }

SCRIPT_DIR="$(cd -- "$(dirname -- "$0")" && pwd)"

# -----------------------------
# Chaotic AUR bootstrap
# -----------------------------
# The keyring and mirrorlist must exist before pacman.conf can include the repo.
if ! grep -q "^\[chaotic-aur\]" /etc/pacman.conf \
    || ! pacman -Q chaotic-keyring chaotic-mirrorlist >/dev/null 2>&1; then
    run sudo pacman-key --init
    run sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com
    run sudo pacman-key --lsign-key 3056513887B78AEB

    # Bootstrap the repo before adding it to pacman.conf.
    run sudo pacman -U --noconfirm \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst' \
        'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
fi

# -----------------------------
# Mirror selection
# -----------------------------
# Upgrade and install reflector first, then use the fast HTTPS mirrors for the
# rest of the bootstrap. Override the country list with REFLECTOR_COUNTRIES;
# an empty value disables the country filter.
REFLECTOR_COUNTRIES="${REFLECTOR_COUNTRIES:-sk,cz,at,de}"

run sudo pacman -Syu --needed --noconfirm reflector

if [[ -f /etc/pacman.d/mirrorlist ]]; then
    run sudo cp -a /etc/pacman.d/mirrorlist \
        "/etc/pacman.d/mirrorlist.bak-$(date +%Y%m%d-%H%M%S)"
fi

reflector_args=(
    --latest 20
    --protocol https
    --sort rate
    --connection-timeout 5
    --download-timeout 5
    --save /etc/pacman.d/mirrorlist
)
if [[ -n "$REFLECTOR_COUNTRIES" ]]; then
    reflector_args+=(--country "$REFLECTOR_COUNTRIES")
fi

if ! run sudo reflector "${reflector_args[@]}"; then
    warn "reflector failed; keeping the existing mirrorlist"
fi

# Re-sync from the selected mirrors before installing the bootstrap tools.
run sudo pacman -Syu --needed --noconfirm

# -----------------------------
# Bootstrap tools
# -----------------------------
run sudo pacman -S --needed --noconfirm base-devel git mold rustup python

# -----------------------------
# pacman and makepkg configuration
# -----------------------------
# Use the same file/edit manifest as the rest of the system so the bootstrap
# and final apply cannot drift apart. python is installed above for apply.py.
if (( DRY_RUN )); then
    sudo python3 "$SCRIPT_DIR/system/apply.py" --diff \
        --filter '^/etc/pacman\.conf$' \
        --filter '^/etc/makepkg\.conf\.d/'
else
    sudo python3 "$SCRIPT_DIR/system/apply.py" --apply --yes \
        --filter '^/etc/pacman\.conf$' \
        --filter '^/etc/makepkg\.conf\.d/'
fi

run rustup default stable

run sudo pacman -S --needed --noconfirm fish helix htop ghostty

if ! command -v yay >/dev/null 2>&1; then
    if (( DRY_RUN )); then
        printf '    [dry-run] git clone https://aur.archlinux.org/yay-bin.git\n'
        printf '    [dry-run] (cd yay-bin && makepkg -si --noconfirm)\n'
    else
        tmpdir="$(mktemp -d)"

        (
            cd "$tmpdir"
            git clone https://aur.archlinux.org/yay-bin.git
            cd yay-bin
            makepkg -si --noconfirm
        )

        rm -rf "$tmpdir"
    fi
fi

run yay -S --needed --noconfirm zen-browser-bin

if (( DRY_RUN )); then
    echo "Dry run complete. No system changes were made."
else
    echo "Done. pacman and makepkg configuration applied."
fi
