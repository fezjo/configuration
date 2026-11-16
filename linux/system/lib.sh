# shellcheck shell=bash
# Shared helpers for the setup entry points.
#
# Source from an entry point in linux/ after `set -euo pipefail`:
#
#   . "$(dirname -- "$0")/system/lib.sh"
#
# Callers keep their own usage() text and post-parse validation. Set the
# CLI_* policy variables before calling parse_args().

# `hostname` is not part of Arch's base install. Use the kernel nodename that
# `hostname -s` would print, without requiring the binary.
short_hostname() {
    local name
    name="$(uname -n)"
    printf '%s\n' "${name%%.*}"
}

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

warn() { printf '    warn: %s\n' "$*" >&2; }

run() {
    if (( DRY_RUN )); then
        printf '    [dry-run] %s\n' "$*"
        return 0
    fi
    "$@"
}

# parse_args "$@"
#
# Handles the options shared by every setup script: -n/--dry-run, --host,
# --form, --cpu, and -h/--help. Callers opt into the rest with:
#
#   CLI_USAGE             usage function to print (default: usage)
#   CLI_POSITIONAL_MODES  accept install|sync|plan as a positional argument
#   CLI_MODE_FLAG         accept --mode NAME
#
# Globals read and written: DRY_RUN, HOST, FORM, CPU, and MODE when enabled.
parse_args() {
    while (( $# )); do
        case "$1" in
            -n|--dry-run) DRY_RUN=1 ;;
            --host) HOST="${2:?--host needs a value}"; shift ;;
            --form) FORM="${2:?--form needs a value}"; shift ;;
            --cpu) CPU="${2:?--cpu needs a value}"; shift ;;
            --mode)
                if (( ${CLI_MODE_FLAG:-0} )); then
                    MODE="${2:?--mode needs a value}"
                    shift
                else
                    "${CLI_USAGE:-usage}" >&2
                    exit 2
                fi
                ;;
            install|sync|plan)
                if (( ${CLI_POSITIONAL_MODES:-0} )); then
                    MODE="$1"
                else
                    "${CLI_USAGE:-usage}" >&2
                    exit 2
                fi
                ;;
            -h|--help) "${CLI_USAGE:-usage}"; exit 0 ;;
            *)
                printf 'error: unknown argument: %s\n' "$1" >&2
                "${CLI_USAGE:-usage}" >&2
                exit 2
                ;;
        esac
        shift
    done
}
