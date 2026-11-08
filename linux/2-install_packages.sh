#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

DRY_RUN=0
list=""

usage() {
    cat <<'EOF'
usage: 2-install_packages.sh [--dry-run] [LIST]

  -n, --dry-run   show installs, updates, and up-to-date packages
  LIST            package list suffix, for example "niri" for packages_niri.md
EOF
}

while (( $# )); do
    case "$1" in
        -n|--dry-run) DRY_RUN=1 ;;
        -h|--help) usage; exit 0 ;;
        -*) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
        *) list="$1" ;;
    esac
    shift
done

if [[ -n "$list" ]]; then
    file="packages_${list}.md"
else
    file="packages.md"
fi
[[ -f "$file" ]] || { echo "missing $file" >&2; exit 1; }

mapfile -t pkgs < <(
    sed -e 's/#.*//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
        -e '/^-/d' -e '/^$/d' -e 's/^+[[:space:]]*//' "$file"
)

(( ${#pkgs[@]} )) || { echo "no packages in $file" >&2; exit 1; }

# The list intentionally contains duplicates; keep the first occurrence.
declare -A seen=()
unique=()
for pkg in "${pkgs[@]}"; do
    [[ -n ${seen[$pkg]:-} ]] && continue
    seen[$pkg]=1
    unique+=("$pkg")
done
pkgs=("${unique[@]}")

if (( ! DRY_RUN )); then
    if ! command -v yay >/dev/null 2>&1; then
        echo "yay is not installed; run 1-pre_installation.sh first" >&2
        exit 1
    fi
    yay -S --needed --noconfirm "${pkgs[@]}"
    exit 0
fi

# Split the list into packages that are absent, upgradable, and up to date.
# `pacman -T` resolves provides and virtual packages, so an installed provider
# counts as satisfied just like it does for `pacman/yay --needed`.
missing_output="$(pacman -T "${pkgs[@]}" 2>/dev/null || true)"
declare -A missing=()
while IFS= read -r pkg; do
    [[ -n "$pkg" ]] && missing["$pkg"]=1
done <<< "$missing_output"

if command -v yay >/dev/null 2>&1; then
    update_output="$(yay -Qu 2>/dev/null || true)"
else
    update_output="$(pacman -Qu 2>/dev/null || true)"
    printf 'note: yay is not installed; AUR updates were not checked\n' >&2
fi

declare -A updates=()
while IFS= read -r line; do
    [[ -n "$line" ]] && updates["${line%% *}"]=1
done <<< "$update_output"

install_pkgs=()
update_pkgs=()
uptodate=0
for pkg in "${pkgs[@]}"; do
    if [[ -n ${updates[$pkg]:-} ]]; then
        update_pkgs+=("$pkg")
    elif [[ -z ${missing[$pkg]:-} ]]; then
        ((uptodate += 1))
    else
        install_pkgs+=("$pkg")
    fi
done

print_group() {
    local label=$1
    shift
    if (( $# == 0 )); then
        printf '%s: none\n' "$label"
        return
    fi
    printf '%s (%d):\n' "$label" "$#"
    printf '%s ' "$@" | fold -s -w 100 | sed -e 's/^/    /' -e 's/ *$//'
    printf '\n'
}

print_group '[dry-run] would install' "${install_pkgs[@]}"
print_group '[dry-run] would update' "${update_pkgs[@]}"
printf '[dry-run] %d package(s) already up to date (not listed)\n' "$uptodate"
