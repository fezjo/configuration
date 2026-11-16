# shellcheck shell=bash
# Shared helpers for the opt-in remote-desktop installers.

# Install the package names listed in a file, ignoring comments and blank lines.
# Missing yay is a warning: the file installation is still useful without the
# packages, and the caller can install them with another AUR helper.
install_packages() {
    local file=$1
    local -a pkgs=()
    mapfile -t pkgs < <(awk '
        { sub(/#.*/, ""); gsub(/^[ \t]+|[ \t]+$/, "") }
        length
    ' "$file")
    (( ${#pkgs[@]} )) || return 0

    if ! command -v yay >/dev/null 2>&1; then
        printf 'warning: yay is not installed; install these packages manually:\n' >&2
        printf '  %s\n' "${pkgs[@]}" >&2
        return 0
    fi

    yay -S --needed --noconfirm "${pkgs[@]}"
}
