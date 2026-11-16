#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "$0")"

. "$(dirname -- "$0")/system/lib.sh"

MODE=install
DRY_RUN=0
HOST="${CONFIG_HOST:-$(short_hostname)}"
FORM=""
CPU=""

usage() {
    cat <<'EOF'
usage: setup.sh [install|sync|plan] [--dry-run] [--host NAME]
                [--form laptop|desktop] [--cpu amd|intel]

  install   bootstrap a new machine (default)
  sync      update configuration on an existing machine without touching
            kernels, initramfs, boot entries, or filesystem layout
  plan      preview the selected mode

  -n, --dry-run   preview without changing anything
  --host NAME     host profile from .chezmoidata/hosts.toml
  --form, --cpu   override hardware detection
EOF
}

CLI_USAGE=usage
CLI_POSITIONAL_MODES=1
parse_args "$@"

if [[ $EUID -eq 0 ]]; then
    die "run setup.sh as your user, not as root"
fi

case "$MODE" in
    install|sync|plan) ;;
    *) die "invalid mode: $MODE" ;;
esac

[[ "$MODE" == plan ]] && DRY_RUN=1

if (( ! DRY_RUN )) && [[ "$HOST" != "$(short_hostname)" ]]; then
    die "refusing to apply host profile '$HOST' on '$(short_hostname)'"
fi

common_args=(--host "$HOST")
[[ -n "$FORM" ]] && common_args+=(--form "$FORM")
[[ -n "$CPU" ]] && common_args+=(--cpu "$CPU")

validate_host() {
    command -v python3 >/dev/null 2>&1 \
        || die "python3 is required to resolve host layers"
    python3 system/hostinfo.py "${common_args[@]}" shell-env >/dev/null \
        || die "cannot resolve host profile '$HOST'"
}

apply_args=(python3 system/apply.py "${common_args[@]}")
(( DRY_RUN )) && apply_args+=(--diff) || apply_args+=(--apply --yes)

if (( DRY_RUN )); then
    echo "Dry run: no system changes will be made."
    echo "Host: $HOST"

    if [[ "$MODE" == install || "$MODE" == plan ]]; then
        echo
        echo "== 1-pre_installation.sh =="
        bash 1-pre_installation.sh --dry-run "${common_args[@]}"
    fi

    echo
    if [[ "$MODE" == sync ]]; then
        dry_mode=sync
    else
        dry_mode=install
    fi
    echo "== 2-install_packages.sh ($dry_mode) =="
    bash 2-install_packages.sh --dry-run --mode "$dry_mode" \
        "${common_args[@]}"

    echo
    echo "== system/apply.py =="
    sudo "${apply_args[@]}"

    echo
    echo "== 3-post_installation.sh =="
    bash 3-post_installation.sh --dry-run "${common_args[@]}"

    echo
    echo "Dry run complete. No changes were made."
    exit 0
fi

if [[ "$MODE" == install ]]; then
    bash 1-pre_installation.sh "${common_args[@]}"
    validate_host
    bash 2-install_packages.sh --mode install "${common_args[@]}"
    sudo "${apply_args[@]}"
    bash 3-post_installation.sh "${common_args[@]}"
    exit 0
fi

validate_host
bash 2-install_packages.sh --mode sync "${common_args[@]}"
sudo "${apply_args[@]}"
bash 3-post_installation.sh "${common_args[@]}"
