#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

if [[ $EUID -eq 0 ]]; then
    echo "run setup.sh as your user, not as root" >&2
    exit 1
fi

bash 1-pre_installation.sh
bash 2-install_packages.sh
sudo bash 4-memory.sh --yes
sudo python3 system/apply.py --apply --yes
bash 3-post_installation.sh
sudo bash system/timeshift.sh --yes
