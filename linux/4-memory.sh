#!/usr/bin/env bash
# 4-memory.sh — portable memory tuning for Arch desktops
#
#   zram (fast tier)  ->  low-priority disk swap (overflow)  ->  systemd-oomd
#
# Designed to be idempotent and safe to re-run. It adapts to the machine:
#   * zram size scales with RAM
#   * swapfile size scales with RAM
#   * btrfs root   -> dedicated @swap subvolume (invisible to timeshift)
#   * ext4/xfs root-> /swapfile
#   * old systemd  -> falls back to ManagedOOMMemoryPressure=kill
#   * no swap      -> creates one; existing disk swap -> left alone
#
# Usage:
#   sudo bash 4-memory.sh                 # apply (asks for confirmation)
#   sudo bash 4-memory.sh --dry-run       # show what would change
#   sudo bash 4-memory.sh --yes           # no confirmation (for setup.sh)
#   sudo bash 4-memory.sh --status        # print current state, change nothing
#   sudo bash 4-memory.sh --rollback      # undo everything this script did
#
# Options (env or flag):
#   --user NAME         target desktop user (default: $SUDO_USER / $USER)
#   --zram-size EXPR    zram-generator size expression (default: min(max(4096, ram / 4), 16384))
#   --swap-size SIZE    disk swap overflow, MiB or 8G (default: RAM/4 clamped to 2–8 GiB)
#   --no-cleanup        never run paccache/journalctl vacuum
#   --no-oomd           only do zram + swap + sysctl
#
# Uninstall / rollback removes only files marked with the "managed-by" header,
# and only deletes the swapfile/subvolume if this script created them.
set -euo pipefail

MARK="# managed-by: 4-memory.sh"
STATE_DIR="/var/lib/setup-memory"
STATE_FILE="$STATE_DIR/state"

# rollback defaults (see load_state): assume nothing was created by us unless
# the state file says otherwise, so a lost/forged state never causes deletions.
FOREIGN_SWAP=""
CREATED_SWAPFILE=0
CREATED_SUBVOL=0
OOMD_WAS_ENABLED=1
STATE_ROOT_SRC=""

# ---------------------------------------------------------------- defaults
MODE="apply"
DRY_RUN=0
ASSUME_YES=0
DO_CLEANUP=1
DO_OOMD=1
TARGET_USER="${SUDO_USER:-${USER:-}}"
ZRAM_SIZE_EXPR=""
SWAP_SIZE_ARG=""
SWAP_PRIO=10
ZRAM_PRIO=100

# session units that should never be chosen as the oomd kill target
USER_UNITS=(
  niri dms pipewire pipewire-pulse wireplumber
  xdg-desktop-portal xdg-desktop-portal-gtk
  xdg-desktop-portal-wlr xdg-document-portal
  gnome-keyring-daemon ssh-agent
)
SYSTEM_UNITS=(dbus-broker tailscaled)

# ---------------------------------------------------------------- output
die()  { printf '\033[31merror:\033[0m %s\n' "$*" >&2; exit 1; }
info() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m %s\n' "$*"; }
skip() { printf '    \033[36mskip\033[0m %s\n' "$*"; }
warn() { printf '    \033[33mwarn\033[0m %s\n' "$*"; }
note() { printf '        %s\n' "$*"; }

# run a command, or just print it in dry-run mode
run() {
  if (( DRY_RUN )); then
    printf '        [dry-run] %s\n' "$*"
    return 0
  fi
  "$@"
}

# write_file DEST [MODE]  (content on stdin)
write_file() {
  local dest="$1" mode="${2:-644}"
  local dir tmp content
  content="$(cat)"
  if (( DRY_RUN )); then
    printf '        [dry-run] write %s\n' "$dest"
    printf '%s\n' "$content" | sed 's/^/        | /'
    return 0
  fi
  dir="$(dirname "$dest")"
  mkdir -p "$dir"
  # Write to a temp file in the same directory and rename over the target, so a
  # pre-existing symlink is replaced instead of followed (avoids root writing
  # through a user-planted link).
  tmp="$(mktemp "$dir/.4-memory.XXXXXX")" || return 1
  if ! printf '%s\n' "$content" > "$tmp"; then
    rm -f "$tmp"
    return 1
  fi
  chmod "$mode" "$tmp"
  mv -f "$tmp" "$dest"
}

# write a drop-in inside the target user's home, refusing to follow a symlinked
# path out of the home directory.
write_user_file() {
  local dest="$1" home dest_real
  home="$(realpath -m "$TARGET_HOME" 2>/dev/null || printf '%s' "$TARGET_HOME")"
  dest_real="$(realpath -m "$dest" 2>/dev/null || printf '%s' "$dest")"
  [[ "$dest_real" == "$home"/* ]] || die "refusing to write outside $TARGET_HOME: $dest"
  write_file "$dest"
}

# load_state  (parse key=value; never source a file as root)
load_state() {
  local k v
  [[ -f "$STATE_FILE" ]] || return 0
  while IFS='=' read -r k v; do
    [[ -n "$k" && "$k" != \#* ]] || continue
    case "$k" in
      SWAPFILE)         SWAPFILE="$v" ;;
      SWAP_MOUNT)       SWAP_MOUNT="$v" ;;
      SUBVOL)           SUBVOL="$v" ;;
      ROOT_SRC)         STATE_ROOT_SRC="$v" ;;
      SWAP_MIB)         SWAP_MIB="$v" ;;
      ZRAM_SIZE)        ZRAM_SIZE_EXPR="$v" ;;
      SD_VER)           SD_VER="$v" ;;
      FOREIGN_SWAP)     FOREIGN_SWAP="$v" ;;
      CREATED_SWAPFILE) CREATED_SWAPFILE="$v" ;;
      CREATED_SUBVOL)   CREATED_SUBVOL="$v" ;;
      OOMD_WAS_ENABLED) OOMD_WAS_ENABLED="$v" ;;
    esac
  done < "$STATE_FILE"
}

# ---------------------------------------------------------------- arguments
while (( $# )); do
  case "$1" in
    --dry-run)      DRY_RUN=1 ;;
    -y|--yes)       ASSUME_YES=1 ;;
    --status)       MODE="status" ;;
    --rollback)     MODE="rollback" ;;
    --no-cleanup)   DO_CLEANUP=0 ;;
    --no-oomd)      DO_OOMD=0 ;;
    --user)         TARGET_USER="${2:?--user needs a value}"; shift ;;
    --zram-size)    ZRAM_SIZE_EXPR="${2:?--zram-size needs a value}"; shift ;;
    --swap-size)    SWAP_SIZE_ARG="${2:?--swap-size needs a value}"; shift ;;
    -h|--help)      sed -n '2,26p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) die "unknown argument: $1 (try --help)" ;;
  esac
  shift
done

if [[ "$MODE" != "status" ]]; then
  [[ $EUID -eq 0 ]] || die "must run as root (use sudo)"
fi

# ---------------------------------------------------------------- detection
ROOT_SRC="$(findmnt -no SOURCE /)"
ROOT_SRC="${ROOT_SRC%%\[*}"          # btrfs: /dev/x[/@] -> /dev/x
ROOT_FSTYPE="$(findmnt -no FSTYPE /)"
ROOT_UUID="$(findmnt -no UUID / || true)"
[[ -n "$ROOT_SRC" ]] || die "cannot determine root device"

# resolve a sane desktop user even under `sudo -i` or a root shell
if [[ -z "$TARGET_USER" || "$TARGET_USER" == "root" ]]; then
  if id 1000 >/dev/null 2>&1; then TARGET_USER="$(id -nu 1000)"; fi
fi
TARGET_HOME="$(getent passwd "$TARGET_USER" 2>/dev/null | cut -d: -f6)"
TARGET_HOME="${TARGET_HOME:-/root}"

MEM_MIB=$(( $(awk '/^MemTotal:/{print $2}' /proc/meminfo) / 1024 ))
SD_VER=$(systemctl --version 2>/dev/null | awk 'NR==1{print $2}' || echo 0)
SD_VER=${SD_VER:-0}

# remember whether oomd was already enabled, so rollback does not disable a
# service that the distribution (not this script) turned on.
OOMD_WAS_ENABLED=1
systemctl is-enabled --quiet systemd-oomd.service 2>/dev/null || OOMD_WAS_ENABLED=0

# 261+ has per-unit OOMRules, 247+ has systemd-oomd, 253+ has ManagedOOMPreference
HAVE_RULES=0;   (( SD_VER >= 261 )) && HAVE_RULES=1
HAVE_OOMD=0;    (( SD_VER >= 247 )) && HAVE_OOMD=1
HAVE_PREF=0;    (( SD_VER >= 253 )) && HAVE_PREF=1

if [[ -z "$ZRAM_SIZE_EXPR" ]]; then
  # Units are MiB. Do NOT use 4G/16G inside the expression: zram-generator
  # treats them as SI megabytes inside expressions (4G -> 4,000,000,000).
  ZRAM_SIZE_EXPR="min(max(4096, ram / 4), 16384)"
fi
# Never interpolate arbitrary text into the root-owned zram config: allow only
# the characters zram-generator expressions need (numbers, ram/min/max, math).
if [[ "$ZRAM_SIZE_EXPR" == *[[:cntrl:]]* ]]; then
  die "invalid --zram-size expression (control characters)"
fi
[[ "$ZRAM_SIZE_EXPR" =~ ^[0-9A-Za-z._+*/()%,[:space:]-]+$ ]] \
  || die "invalid --zram-size expression: $ZRAM_SIZE_EXPR"

if [[ -z "$SWAP_SIZE_ARG" ]]; then
  swap_mib=$(( MEM_MIB / 4 ))
  (( swap_mib < 2048 )) && swap_mib=2048
  (( swap_mib > 8192 )) && swap_mib=8192
  SWAP_SIZE_ARG="${swap_mib}M"
fi
# normalise SIZE to MiB for space checks and to the "8G" form btrfs wants
parse_mib() {
  local v="$1"
  # Validate before putting the value anywhere near arithmetic expansion
  # (bash evaluates command substitutions inside $(( ... ))).
  [[ "$v" =~ ^[0-9]+[GgMmKk]?$ ]] || die "invalid --swap-size '$v' (use MiB or e.g. 8G)"
  case "$v" in
    *[Gg]) echo $(( ${v%[Gg]} * 1024 )) ;;
    *[Mm]) echo $(( ${v%[Mm]} )) ;;
    *[Kk]) echo $(( ${v%[Kk]} / 1024 )) ;;
    *)     echo "$v" ;;
  esac
}
SWAP_MIB=$(parse_mib "$SWAP_SIZE_ARG")

if [[ "$ROOT_FSTYPE" == "btrfs" ]]; then
  SWAPFILE="/swap/swapfile"
  SWAP_MOUNT="/swap"
  SUBVOL="@swap"
else
  SWAPFILE="/swapfile"          # ext4/xfs: no subvolume, no mount needed
  SWAP_MOUNT=""
  SUBVOL=""
fi

# ---------------------------------------------------------------- status
print_status() {
  info "System"
  note "root:      $ROOT_SRC ($ROOT_FSTYPE${ROOT_UUID:+, UUID $ROOT_UUID})"
  note "RAM:       ${MEM_MIB} MiB"
  note "systemd:   $SD_VER (oomd=$HAVE_OOMD rulesets=$HAVE_RULES preference=$HAVE_PREF)"
  note "user:      ${TARGET_USER:-<unknown>}"

  info "Swap"
  swapon --show 2>/dev/null || echo "    (none)"
  note "zram:      $(cat /sys/block/zram0/disksize 2>/dev/null || echo 'no zram0')"
  note "zram cfg:  $(grep -E '^(zram-size|swap-priority)' /etc/systemd/zram-generator.conf 2>/dev/null | tr '\n' ' ' || true)"

  info "Sysctl"
  note "swappiness=$(sysctl -n vm.swappiness) page-cluster=$(sysctl -n vm.page-cluster) watermark_scale_factor=$(sysctl -n vm.watermark_scale_factor)"

  info "oomd"
  note "service:   $(systemctl is-active systemd-oomd.service 2>/dev/null || true)"
  note "ruleset:   $([[ -f /etc/systemd/oomd/rules.d/desktop.oomrule ]] && echo present || echo absent)"
  note "OOMRules:  $(systemctl show "user@$(id -u "${TARGET_USER:-0}").service" -p OOMRules 2>/dev/null | head -1 || echo unknown)"
  if command -v oomctl >/dev/null && systemctl is-active -q systemd-oomd.service; then
    oomctl 2>/dev/null | head -20 | sed 's/^/        /'
  fi
  note "psi full avg300: $(awk '/^full/{for(i=1;i<=NF;i++) if($i ~ /^avg300=/){sub("avg300=","",$i); print $i}}' /proc/pressure/memory)"

  if [[ -f "$STATE_FILE" ]]; then
    info "Last apply"
    sed 's/^/        /' "$STATE_FILE"
  fi
}

if [[ "$MODE" == "status" ]]; then
  print_status
  exit 0
fi

# ---------------------------------------------------------------- rollback
do_rollback() {
  info "Rollback"
  if (( ! ASSUME_YES && ! DRY_RUN )); then
    read -r -p "Remove the swapfile, oomd config and sysctl tuning added by this script? [y/N] " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { echo "aborted"; exit 1; }
  fi
  local fs_swapfile="$SWAPFILE" subvol="$SUBVOL" swapmount="$SWAP_MOUNT"
  local created_swapfile=0 created_subvol=0 foreign_swap=0 oomd_was_enabled=1
  local same_root=1
  if [[ -f "$STATE_FILE" ]]; then
    load_state
    if [[ -n "$STATE_ROOT_SRC" && "$STATE_ROOT_SRC" != "$ROOT_SRC" ]]; then
      warn "state was written for $STATE_ROOT_SRC, current root is $ROOT_SRC; not deleting anything"
      swapmount=""
      foreign_swap=1
      same_root=0
    else
      fs_swapfile="${SWAPFILE:-$fs_swapfile}"
      subvol="$SUBVOL"
      swapmount="$SWAP_MOUNT"
      created_swapfile="${CREATED_SWAPFILE:-0}"
      created_subvol="${CREATED_SUBVOL:-0}"
      foreign_swap="${FOREIGN_SWAP:-0}"
      oomd_was_enabled="${OOMD_WAS_ENABLED:-1}"
      # Coerce flags to 0/1: they are used in (( )) and must never contain
      # attacker-controlled arithmetic expressions.
      case "$created_swapfile" in 1) created_swapfile=1 ;; *) created_swapfile=0 ;; esac
      case "$created_subvol"   in 1) created_subvol=1   ;; *) created_subvol=0   ;; esac
      case "$foreign_swap"     in 1) foreign_swap=1     ;; *) foreign_swap=0     ;; esac
      case "$oomd_was_enabled" in 0) oomd_was_enabled=0 ;; *) oomd_was_enabled=1 ;; esac
    fi
  fi

  if (( foreign_swap )); then
    skip "leaving pre-existing swap $fs_swapfile alone"
  elif (( created_swapfile )) && [[ -f "$fs_swapfile" ]]; then
    run swapoff "$fs_swapfile" 2>/dev/null && ok "swapoff $fs_swapfile" || skip "$fs_swapfile not active"
  elif [[ -f "$fs_swapfile" ]]; then
    skip "$fs_swapfile existed before this script; leaving it active"
  fi
  if (( oomd_was_enabled )); then
    skip "systemd-oomd was already enabled before setup; leaving it"
  else
    run systemctl disable --now systemd-oomd.service systemd-oomd.socket >/dev/null 2>&1 \
      && ok "systemd-oomd disabled" || skip "systemd-oomd was not enabled"
  fi

  for f in \
    /etc/systemd/oomd.conf.d/60-local.conf \
    /etc/systemd/oomd/rules.d/desktop.oomrule \
    /etc/systemd/user@.service.d/60-oom.conf \
    /etc/sysctl.d/90-memory.conf \
    /etc/systemd/system/dbus-broker.service.d/60-oom.conf \
    /etc/systemd/system/tailscaled.service.d/60-oom.conf
  do
    [[ -f "$f" ]] || continue
    if grep -qF "$MARK" "$f" 2>/dev/null; then
      run rm -f "$f" && ok "removed $f"
    else
      skip "$f not created by this script"
    fi
  done
  for u in "${USER_UNITS[@]}"; do
    f="$TARGET_HOME/.config/systemd/user/$u.service.d/60-oom.conf"
    [[ -f "$f" ]] || continue
    if grep -qF "$MARK" "$f" 2>/dev/null; then
      run rm -f "$f" && ok "removed $f"
    else
      skip "$f not created by this script"
    fi
  done

  if grep -qF "$MARK (fstab)" /etc/fstab 2>/dev/null; then
    run sed -i "\|^$MARK (fstab) begin|,\|^$MARK (fstab) end|d" /etc/fstab
    ok "fstab entries removed"
  fi

  if (( ! same_root )); then
    skip "root device changed; not restoring zram config"
  elif [[ -f "$STATE_DIR/zram-generator.conf.orig" ]]; then
    run cp -a "$STATE_DIR/zram-generator.conf.orig" /etc/systemd/zram-generator.conf
    ok "zram config restored (reboot to apply)"
  else
    skip "no zram backup to restore"
  fi

  run systemctl daemon-reload
  if (( same_root )) && [[ "$ROOT_FSTYPE" == "btrfs" && -n "$swapmount" ]]; then
    run umount "$swapmount" 2>/dev/null || true
    run rmdir "$swapmount" 2>/dev/null || true
  fi
  if [[ "$ROOT_FSTYPE" == "btrfs" && -n "$subvol" ]]; then
    if (( ! created_subvol )); then
      skip "subvolume $subvol was not created by this script; leaving it"
    else
      run mkdir -p /mnt/btrfs-root
      run mount -o subvolid=5 "$ROOT_SRC" /mnt/btrfs-root 2>/dev/null || true
      if btrfs subvolume show "/mnt/btrfs-root/$subvol" >/dev/null 2>&1; then
        run btrfs subvolume delete "/mnt/btrfs-root/$subvol" && ok "$subvol deleted"
      fi
      run umount /mnt/btrfs-root 2>/dev/null || true
      run rmdir /mnt/btrfs-root 2>/dev/null || true
    fi
  fi
  if (( created_swapfile )); then
    if [[ "$fs_swapfile" == "/swapfile" && -f /swapfile ]]; then
      run rm -f /swapfile && ok "/swapfile deleted"
    elif [[ -f "$fs_swapfile" ]]; then
      run rm -f "$fs_swapfile" && ok "$fs_swapfile deleted"
    fi
  fi

  if [[ -n "$TARGET_USER" ]]; then
    runuser -u "$TARGET_USER" -- env XDG_RUNTIME_DIR="/run/user/$(id -u "$TARGET_USER")" \
      systemctl --user daemon-reload >/dev/null 2>&1 || true
  fi
  run sysctl --system >/dev/null 2>&1 || true
  run rm -rf "$STATE_DIR"
  if (( DRY_RUN )); then
    ok "dry-run complete, nothing changed"
    return 0
  fi
  ok "rollback complete — reboot to restore the previous zram size"
}

if [[ "$MODE" == "rollback" ]]; then
  do_rollback
  exit 0
fi

# ---------------------------------------------------------------- preflight
[[ -n "$TARGET_USER" ]] && id "$TARGET_USER" >/dev/null 2>&1 \
  || die "target user '$TARGET_USER' does not exist (use --user NAME)"

info "Plan"
note "zram0:     $ZRAM_SIZE_EXPR (priority $ZRAM_PRIO, zstd)"
note "swapfile:  $SWAPFILE (${SWAP_MIB} MiB, priority $SWAP_PRIO)"
note "sysctl:    vm.swappiness / vm.page-cluster / vm.watermark_scale_factor"
if (( DO_OOMD && HAVE_OOMD && HAVE_RULES )); then
  note "oomd:      ruleset 'desktop' (kill-by-pgscan), protects session units"
elif (( DO_OOMD && HAVE_OOMD )); then
  note "oomd:      legacy ManagedOOMMemoryPressure=kill (systemd $SD_VER < 261)"
else
  note "oomd:      skipped (systemd $SD_VER too old / --no-oomd)"
fi
note "cleanup:   $([[ $DO_CLEANUP -eq 1 ]] && echo 'paccache + journal vacuum when space is tight' || echo 'disabled')"

if (( ! ASSUME_YES && ! DRY_RUN )); then
  read -r -p "Apply? [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]] || { echo "aborted"; exit 1; }
fi

# ------------------------------------------------- phase 0: packages/space
info "Phase 0: packages and free space"
if command -v pacman >/dev/null; then
  for pkg in zram-generator pacman-contrib; do
    if ! pacman -Q "$pkg" >/dev/null 2>&1; then
      run pacman -S --needed --noconfirm "$pkg" || warn "could not install $pkg"
    else
      skip "$pkg already installed"
    fi
  done
else
  warn "not an Arch system: install zram-generator by hand"
fi

avail_mib() { df -B1M --output=avail / | tail -1; }
need=$(( SWAP_MIB + 2048 ))
avail=$(avail_mib)
if (( avail < need )); then
  warn "only ${avail} MiB free, need ${need} MiB"
  if (( DO_CLEANUP )); then
    command -v paccache >/dev/null && run paccache -rk1 || warn "paccache unavailable"
    run journalctl --vacuum-size=500M >/dev/null 2>&1 || warn "journal vacuum failed"
    avail=$(avail_mib)
    ok "$(( avail )) MiB free after cleanup"
  fi
fi
(( avail >= need )) || die "not enough free space for a ${SWAP_MIB} MiB swapfile (have ${avail} MiB)"

# ------------------------------------------------------------- zram config
info "Phase 1: zram"
if [[ ! -f "$STATE_DIR/zram-generator.conf.orig" && -f /etc/systemd/zram-generator.conf ]]; then
  run mkdir -p "$STATE_DIR"
  (( DRY_RUN )) || chmod 700 "$STATE_DIR"
  (( DRY_RUN )) || cp -a /etc/systemd/zram-generator.conf "$STATE_DIR/zram-generator.conf.orig"
  ok "original zram config backed up"
fi
write_file /etc/systemd/zram-generator.conf <<EOF
$MARK
# Fast swap tier. Priority $ZRAM_PRIO outranks the disk swapfile below,
# so zram is always filled first.
[zram0]
compression-algorithm = zstd
zram-size = $ZRAM_SIZE_EXPR
swap-priority = $ZRAM_PRIO
EOF
ok "written (resizes on reboot; a live zram is never touched)"

if [[ -f /sys/module/zswap/parameters/enabled ]] && [[ "$(cat /sys/module/zswap/parameters/enabled)" == "Y" ]]; then
  warn "zswap is ENABLED and would compress pages twice (zswap->zram)"
  note "add 'zswap.enabled=0' to the kernel cmdline and regenerate the initramfs"
fi

# ------------------------------------------------------------------- swap
info "Phase 2: disk swap overflow"
FOREIGN_SWAP=""
existing_disk_swap="$(swapon --show=NAME --noheadings 2>/dev/null | grep -v '^/dev/zram' | head -1 || true)"
if [[ -n "$existing_disk_swap" && "$existing_disk_swap" != "$SWAPFILE" ]]; then
  warn "disk swap already active: $existing_disk_swap — using it instead of $SWAPFILE"
  FOREIGN_SWAP="$existing_disk_swap"
  SWAPFILE="$existing_disk_swap"
  SWAP_MOUNT=""
fi

if [[ -n "$FOREIGN_SWAP" ]]; then
  skip "not touching existing swap"
elif [[ "$ROOT_FSTYPE" == "btrfs" ]]; then
  run mkdir -p /mnt/btrfs-root
  if ! mountpoint -q /mnt/btrfs-root; then
    run mount -o subvolid=5 "$ROOT_SRC" /mnt/btrfs-root
  fi
  if btrfs subvolume show "/mnt/btrfs-root/$SUBVOL" >/dev/null 2>&1; then
    skip "subvolume $SUBVOL exists"
  else
    run btrfs subvolume create "/mnt/btrfs-root/$SUBVOL"
    CREATED_SUBVOL=1
    ok "subvolume $SUBVOL created (timeshift ignores it)"
  fi
  run umount /mnt/btrfs-root 2>/dev/null || true
  run rmdir /mnt/btrfs-root 2>/dev/null || true
fi

if [[ -n "$FOREIGN_SWAP" ]]; then
  :
elif grep -qF "$MARK (fstab) begin" /etc/fstab; then
  skip "fstab entries already present"
else
  if [[ -n "$SWAP_MOUNT" ]]; then
    fstab_block="$MARK (fstab) begin
UUID=$ROOT_UUID $SWAP_MOUNT btrfs rw,noatime,ssd,space_cache=v2,subvol=/$SUBVOL 0 0
$SWAPFILE none swap defaults,pri=$SWAP_PRIO 0 0
$MARK (fstab) end"
  else
    fstab_block="$MARK (fstab) begin
$SWAPFILE none swap defaults,pri=$SWAP_PRIO 0 0
$MARK (fstab) end"
  fi

  if (( DRY_RUN )); then
    printf '        [dry-run] append to /etc/fstab:\n%s\n' "$fstab_block" | sed 's/^/        /'
  else
    cp -a /etc/fstab "/etc/fstab.bak-4-memory"
    printf '\n%s\n' "$fstab_block" >> /etc/fstab
    systemctl daemon-reload
  fi
  ok "fstab entries added"
fi

if [[ -n "$FOREIGN_SWAP" ]]; then
  skip "using existing swap $SWAPFILE"
else
  if [[ -n "$SWAP_MOUNT" ]]; then
    run mkdir -p "$SWAP_MOUNT"
    if ! mountpoint -q "$SWAP_MOUNT"; then
      run mount "$SWAP_MOUNT" || die "could not mount $SWAP_MOUNT (check /etc/fstab)"
    fi
  fi
  if [[ ! -e "$SWAPFILE" ]]; then
    if [[ "$ROOT_FSTYPE" == "btrfs" ]]; then
      run btrfs filesystem mkswapfile --size "$SWAP_SIZE_ARG" --uuid clear "$SWAPFILE"
    else
      run fallocate -l "$SWAP_SIZE_ARG" "$SWAPFILE"
      run chmod 600 "$SWAPFILE"
      run mkswap --uuid clear "$SWAPFILE" >/dev/null
    fi
    CREATED_SWAPFILE=1
    ok "$SWAPFILE created (${SWAP_MIB} MiB)"
  else
    skip "$SWAPFILE exists"
  fi
  run chmod 600 "$SWAPFILE"
  if ! swapon --show=NAME --noheadings 2>/dev/null | grep -qxF "$SWAPFILE"; then
    run swapon "$SWAPFILE"
    ok "swapfile enabled"
  else
    skip "swapfile already active"
  fi
fi

# ----------------------------------------------------------------- sysctl
info "Phase 3: sysctl"
if [[ -d /sys/block/zram0 ]]; then
  swappiness=150   # prefer compressed RAM over the disk swapfile
  page_cluster=0   # no readahead: zram reads are cheap
else
  swappiness=60
  page_cluster=3
fi
write_file /etc/sysctl.d/90-memory.conf <<EOF
$MARK
# zram-first swapping
vm.swappiness = $swappiness
vm.page-cluster = $page_cluster
vm.watermark_scale_factor = 125
EOF
run sysctl -q --system
ok "swappiness=$swappiness page-cluster=$page_cluster watermark_scale_factor=125"

# ------------------------------------------------------------------- oomd
if (( DO_OOMD && HAVE_OOMD )); then
  info "Phase 4: systemd-oomd"
  write_file /etc/systemd/oomd.conf.d/60-local.conf <<EOF
$MARK
[OOM]
DefaultMemoryPressureLimit=60%
DefaultMemoryPressureDurationSec=20s
EOF

  if (( HAVE_RULES )); then
    write_file /etc/systemd/oomd/rules.d/desktop.oomrule <<EOF
$MARK
# Kill the descendant cgroup doing the most reclaim (the browser/Electron
# scope that is thrashing), not the whole session.
[Rule]
MemoryPressureAbove=55%
Action=kill-by-pgscan
LastingSec=15s
EOF
    write_file /etc/systemd/system/user@.service.d/60-oom.conf <<EOF
$MARK
[Service]
OOMRules=desktop
EOF
    ok "ruleset 'desktop' configured"
  else
    write_file /etc/systemd/system/user@.service.d/60-oom.conf <<EOF
$MARK
[Service]
ManagedOOMMemoryPressure=kill
ManagedOOMMemoryPressureLimit=50%
ManagedOOMMemoryPressureDurationSec=15s
EOF
    ok "legacy pressure kill configured (systemd $SD_VER)"
  fi

  if (( HAVE_PREF )); then
    protected=()
    for u in "${SYSTEM_UNITS[@]}"; do
      if [[ -e "/usr/lib/systemd/system/$u.service" || -e "/etc/systemd/system/$u.service" ]]; then
        write_file "/etc/systemd/system/$u.service.d/60-oom.conf" <<EOF
$MARK
[Service]
ManagedOOMPreference=avoid
EOF
        protected+=("$u")
      else
        skip "$u.service not installed"
      fi
    done
    user_cfg_written=0
    cfg_config_existed=1
    if [[ ! -d "$TARGET_HOME/.config" ]]; then cfg_config_existed=0; fi
    for u in "${USER_UNITS[@]}"; do
      if [[ -e "/usr/lib/systemd/user/$u.service" || -e "/etc/systemd/user/$u.service" || -e "$TARGET_HOME/.config/systemd/user/$u.service" ]]; then
        write_user_file "$TARGET_HOME/.config/systemd/user/$u.service.d/60-oom.conf" <<EOF
$MARK
[Service]
ManagedOOMPreference=avoid
EOF
        protected+=("$u")
        user_cfg_written=1
      else
        skip "$u.service not installed"
      fi
    done
    if (( ${#protected[@]} )); then
      # Only hand ownership to the desktop user when the home really belongs to
      # them (never /root, never another user's home).
      if (( user_cfg_written )) && [[ "$TARGET_HOME" != "/root" ]] \
         && [[ "$(stat -c %U "$TARGET_HOME" 2>/dev/null || true)" == "$TARGET_USER" ]]; then
        (( DRY_RUN )) || chown -R "$TARGET_USER:" "$TARGET_HOME/.config/systemd"
        # If we had to create ~/.config itself, hand it over too (non-recursive,
        # so nothing else in the home directory is touched).
        if (( ! cfg_config_existed )); then
          (( DRY_RUN )) || chown "$TARGET_USER:" "$TARGET_HOME/.config"
        fi
      elif (( user_cfg_written )); then
        warn "not chowning $TARGET_HOME (not owned by $TARGET_USER)"
      fi
      ok "protected: ${protected[*]}"
    fi
  else
    skip "ManagedOOMPreference needs systemd >= 253"
  fi

  run systemctl daemon-reload
  run systemctl enable --now systemd-oomd.socket systemd-oomd.service
  run systemctl restart systemd-oomd.service
  if (( HAVE_RULES )) && ! (( DRY_RUN )); then
    systemctl set-property "user@$(id -u "$TARGET_USER").service" OOMRules=desktop 2>/dev/null \
      || warn "OOMRules applies on next login"
  fi
  if (( DRY_RUN )); then
    printf '    [dry-run] runuser -u %s -- systemctl --user daemon-reload\n' "$TARGET_USER"
  else
    runuser -u "$TARGET_USER" -- env XDG_RUNTIME_DIR="/run/user/$(id -u "$TARGET_USER")" \
      systemctl --user daemon-reload >/dev/null 2>&1 \
      && ok "user manager reloaded" \
      || warn "log out/in to apply the protect list"
  fi
else
  info "Phase 4: systemd-oomd skipped"
fi

# ------------------------------------------------------------------ state
if ! (( DRY_RUN )); then
  mkdir -p "$STATE_DIR"
  chmod 700 "$STATE_DIR"
  {
    printf 'SWAPFILE=%s\n' "$SWAPFILE"
    printf 'SWAP_MOUNT=%s\n' "$SWAP_MOUNT"
    printf 'SUBVOL=%s\n' "$SUBVOL"
    printf 'ROOT_FSTYPE=%s\n' "$ROOT_FSTYPE"
    printf 'ROOT_SRC=%s\n' "$ROOT_SRC"
    printf 'SWAP_MIB=%s\n' "$SWAP_MIB"
    printf 'ZRAM_SIZE=%s\n' "$ZRAM_SIZE_EXPR"
    printf 'SD_VER=%s\n' "$SD_VER"
    printf 'FOREIGN_SWAP=%s\n' "$([[ -n "$FOREIGN_SWAP" ]] && echo 1 || echo 0)"
    printf 'CREATED_SWAPFILE=%s\n' "$CREATED_SWAPFILE"
    printf 'CREATED_SUBVOL=%s\n' "$CREATED_SUBVOL"
    printf 'OOMD_WAS_ENABLED=%s\n' "$OOMD_WAS_ENABLED"
  } > "$STATE_FILE"
  chmod 600 "$STATE_FILE"
fi

# ----------------------------------------------------------------- verify
info "Phase 5: verification"
if (( DRY_RUN )); then
  ok "dry-run complete, nothing changed"
  exit 0
fi
echo
swapon --show | sed 's/^/    /'
echo
free -h | sed 's/^/    /'
if (( DO_OOMD && HAVE_OOMD )); then
  echo
  printf '    oomd: %s\n' "$(systemctl is-active systemd-oomd.service)"
  oomctl 2>/dev/null | head -15 | sed 's/^/    /' || true
fi

cat <<EOF

$(printf '\033[1;32mDone.\033[0m')
Reboot to apply the new zram size (a live zram is intentionally not resized).
Verify after reboot:
    swapon --show && zramctl && oomctl
    journalctl -u systemd-oomd -b --no-pager | tail -30

Undo:
    sudo bash $0 --rollback
EOF
