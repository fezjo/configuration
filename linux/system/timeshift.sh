#!/usr/bin/env bash
# Configure Timeshift for the current root filesystem.
#
# Usage:
#   sudo bash linux/system/timeshift.sh --dry-run
#   sudo bash linux/system/timeshift.sh --yes
set -euo pipefail

LINUX_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
TEMPLATE="$LINUX_DIR/root/etc/timeshift/timeshift.json"
TARGET="/etc/timeshift/timeshift.json"
DRY_RUN=0
ASSUME_YES=0

die() { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok() { printf '    \033[32mok\033[0m %s\n' "$*"; }
run() {
    if (( DRY_RUN )); then
        printf '        [dry-run] %s\n' "$*"
    else
        "$@"
    fi
}

while (( $# )); do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        -y|--yes) ASSUME_YES=1 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) die "unknown argument: $1" ;;
    esac
    shift
done

if (( ! DRY_RUN )) && [[ $EUID -ne 0 ]]; then
    die "run as root (or use --dry-run)"
fi

root_src=$(findmnt -no SOURCE /)
root_src=${root_src%%\[*}
root_fstype=$(findmnt -no FSTYPE /)
root_uuid=$(lsblk -no UUID "$root_src" | head -1)
[[ -n "$root_uuid" ]] || die "cannot determine root filesystem UUID"

parent_uuid=""
if command -v cryptsetup >/dev/null 2>&1 && cryptsetup status "$root_src" >/dev/null 2>&1; then
    parent_dev=$(cryptsetup status "$root_src" | awk '/device:/{print $2}')
    [[ -n "$parent_dev" ]] && parent_uuid=$(lsblk -no UUID "$parent_dev" | head -1)
else
    parent_dev=$(lsblk -no PKNAME "$root_src" | head -1)
    [[ -n "$parent_dev" ]] && parent_uuid=$(lsblk -no UUID "/dev/$parent_dev" | head -1)
fi

# Unprivileged fallback for LUKS: lsblk -s lists the filesystem first and the
# parent device second.
if [[ -z "$parent_uuid" ]]; then
    parent_uuid=$(lsblk -s -no UUID "$root_src" | grep -v '^$' | sed -n '2p')
fi

info "Plan"
printf '    root:        %s (%s)\n' "$root_src" "$root_fstype"
printf '    root UUID:   %s\n' "$root_uuid"
printf '    parent UUID: %s\n' "${parent_uuid:-<none>}"
printf '    config:      %s\n' "$TARGET"

if (( ! ASSUME_YES && ! DRY_RUN )); then
    read -r -p "Write Timeshift config? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || die "aborted"
fi

source_file="$TARGET"
[[ -f "$source_file" ]] || source_file="$TEMPLATE"
[[ -f "$source_file" ]] || die "missing $TEMPLATE"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cp "$source_file" "$tmp"

sed -i -E \
    -e "s|\"backup_device_uuid\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"backup_device_uuid\" : \"$root_uuid\"|" \
    -e "s|\"parent_device_uuid\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"parent_device_uuid\" : \"${parent_uuid:-$root_uuid}\"|" \
    -e 's|"do_first_run"[[:space:]]*:[[:space:]]*"[^"]*"|"do_first_run" : "false"|' \
    -e "s|\"btrfs_mode\"[[:space:]]*:[[:space:]]*\"[^\"]*\"|\"btrfs_mode\" : \"$([[ "$root_fstype" == "btrfs" ]] && echo true || echo false)\"|" \
    -e 's|"include_btrfs_home"[[:space:]]*:[[:space:]]*"[^"]*"|"include_btrfs_home" : "false"|' \
    -e 's|"include_btrfs_home_for_backup"[[:space:]]*:[[:space:]]*"[^"]*"|"include_btrfs_home_for_backup" : "false"|' \
    -e 's|"include_btrfs_home_for_restore"[[:space:]]*:[[:space:]]*"[^"]*"|"include_btrfs_home_for_restore" : "false"|' \
    -e 's|"schedule_boot"[[:space:]]*:[[:space:]]*"[^"]*"|"schedule_boot" : "true"|' \
    -e 's|"schedule_hourly"[[:space:]]*:[[:space:]]*"[^"]*"|"schedule_hourly" : "true"|' \
    -e 's|"schedule_daily"[[:space:]]*:[[:space:]]*"[^"]*"|"schedule_daily" : "true"|' \
    -e 's|"schedule_weekly"[[:space:]]*:[[:space:]]*"[^"]*"|"schedule_weekly" : "true"|' \
    -e 's|"schedule_monthly"[[:space:]]*:[[:space:]]*"[^"]*"|"schedule_monthly" : "true"|' \
    "$tmp"

if (( DRY_RUN )); then
    printf '        [dry-run] install %s -> %s\n' "$source_file" "$TARGET"
    sed 's/^/        | /' "$tmp"
    exit 0
fi

install -Dm0644 "$tmp" "$TARGET"
run systemctl enable --now cronie
ok "wrote $TARGET"
ok "Timeshift configured; create the first snapshot with: sudo timeshift --create --comments initial"
