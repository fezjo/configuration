#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

. "$(dirname -- "$0")/system/lib.sh"

DRY_RUN=0
MODE=sync
HOST="${CONFIG_HOST:-}"
FORM=""
CPU=""

usage() {
    cat <<'EOF'
usage: 2-install_packages.sh [--dry-run] [--host NAME] [--mode install|sync]
                             [--form laptop|desktop] [--cpu amd|intel]

  -n, --dry-run   show installs, updates, and up-to-date packages
  --host NAME     host profile from .chezmoidata/hosts.toml (default: hostname)
  --mode MODE     "sync" keeps existing boot/kernel setup; "install" adds
                  install-only packages (default: sync)
  --form, --cpu   override hardware detection
EOF
}

CLI_USAGE=usage
CLI_MODE_FLAG=1
parse_args "$@"

case "$MODE" in
    install|sync) ;;
    *) echo "invalid --mode: $MODE" >&2; exit 2 ;;
esac

if [[ -z "$HOST" ]]; then
    HOST="$(short_hostname)"
fi

command -v python3 >/dev/null 2>&1 || {
    echo "python3 is required; run 1-pre_installation.sh first" >&2
    exit 1
}

resolver=(python3 system/hostinfo.py --host "$HOST")
[[ -n "$FORM" ]] && resolver+=(--form "$FORM")
[[ -n "$CPU" ]] && resolver+=(--cpu "$CPU")
resolver+=(packages --mode "$MODE")

mapfile -t list_files < <("${resolver[@]}")
(( ${#list_files[@]} )) || {
    echo "no package layers resolved for $HOST" >&2
    exit 1
}

declare -A chosen=()
order=()

for file in "${list_files[@]}"; do
    while IFS= read -r raw || [[ -n "$raw" ]]; do
        line=${raw%%#*}
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "$line" ]] || continue

        sign=${line:0:1}
        pkg=${line:1}
        pkg="${pkg#"${pkg%%[![:space:]]*}"}"
        pkg="${pkg%"${pkg##*[![:space:]]}"}"
        [[ -n "$pkg" ]] || continue

        case "$sign" in
            +)
                if [[ -z ${chosen[$pkg]:-} ]]; then
                    order+=("$pkg")
                fi
                chosen[$pkg]=1
                ;;
            -)
                chosen[$pkg]=0
                ;;
        esac
    done < "$file"
done

pkgs=()
for pkg in "${order[@]}"; do
    if [[ ${chosen[$pkg]:-0} == 1 ]]; then
        pkgs+=("$pkg")
    fi
done

(( ${#pkgs[@]} )) || { echo "no packages selected for $HOST" >&2; exit 1; }

if (( DRY_RUN )); then
    printf 'package layers:\n'
    printf '    %s\n' "${list_files[@]}"
    printf '\n'
fi

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
