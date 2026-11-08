#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

DRY_RUN=0

usage() {
    cat <<'EOF'
usage: setup.sh [--dry-run]

  -n, --dry-run   print the install plan and preview every stage
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

if [[ $EUID -eq 0 ]]; then
    echo "run setup.sh as your user, not as root" >&2
    exit 1
fi

if (( DRY_RUN )); then
    echo "Dry run: no system changes will be made."
    echo
    echo "== 1-pre_installation.sh =="
    bash 1-pre_installation.sh --dry-run
    echo
    echo "== 2-install_packages.sh =="
    bash 2-install_packages.sh --dry-run niri
    echo
    echo "== 4-memory.sh =="
    # The memory script is read-only in --dry-run mode, so no sudo is needed.
    bash 4-memory.sh --dry-run
    echo
    echo "== system/apply.py =="
    # pacman/makepkg were already previewed by 1-pre. The remaining manifest
    # includes 0440 files such as /etc/sudoers.d, so reading it needs root.
    if command -v python3 >/dev/null 2>&1; then
        sudo python3 system/apply.py --diff \
            --exclude '^/etc/pacman\.conf$' \
            --exclude '^/etc/makepkg\.conf\.d/'
    else
        echo "python3 is not installed; skipping the system file diff preview"
    fi
    echo
    echo "== 3-post_installation.sh =="
    bash 3-post_installation.sh --dry-run
    echo
    echo "== system/timeshift.sh =="
    bash system/timeshift.sh --dry-run
    echo
    echo "Dry run complete. No changes were made."
    exit 0
fi

bash 1-pre_installation.sh
bash 2-install_packages.sh niri
sudo bash 4-memory.sh --yes
sudo python3 system/apply.py --apply --yes
bash 3-post_installation.sh
sudo bash system/timeshift.sh --yes
