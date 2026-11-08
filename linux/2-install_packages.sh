#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

list="${1:-}"
if [[ -n "$list" ]]; then
    file="packages_${list}.md"
else
    file="packages.md"
fi
[[ -f "$file" ]] || { echo "missing $file" >&2; exit 1; }

mapfile -t pkgs < <(
    sed 's/#.*//; s/^\s*//; s/\s*$//; /^-/d; /^\s*$/d; s/^+ //' "$file"
)

(( ${#pkgs[@]} )) || { echo "no packages in $file" >&2; exit 1; }
yay -S --needed --noconfirm "${pkgs[@]}"
