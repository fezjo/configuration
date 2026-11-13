#!/usr/bin/env bash
# Publish the running Hyprland instance's environment to the systemd user
# manager and the D-Bus activation environment.
#
# D-Bus/systemd activated applications (portals, single-instance apps, KDE
# session services) inherit the user manager's environment, not the
# compositor's. If that environment still names a previous Hyprland socket,
# those applications open on the old or dead display instead of this one.
# Hyprland started from a bare TTY does not update that environment by itself.
#
# This mirrors what Umbriel does in Server::sessionEnvironmentCommand():
# import the session variables and update the D-Bus activation environment.
#
# Install to ~/.config/hypr/session-env.sh (mise run hypr:install-session-env)
# and call it from hyprland.lua:
#
#   hl.on("hyprland.start", function()
#     hl.exec_cmd("$HOME/.config/hypr/session-env.sh")
#   end)
#   hl.on("hyprland.shutdown", function()
#     hl.exec_cmd("$HOME/.config/hypr/session-env.sh --clear")
#   end)
#
#   session-env.sh          publish this instance's environment
#   session-env.sh --clear  remove it again if it is still the published one

set -u

VARS=(
  WAYLAND_DISPLAY
  DISPLAY
  XDG_CURRENT_DESKTOP
  XDG_SESSION_DESKTOP
  XDG_SESSION_TYPE
  XCURSOR_THEME
  XCURSOR_SIZE
  HYPRLAND_INSTANCE_SIGNATURE
)

present=()
for name in "${VARS[@]}"; do
  [ -n "${!name+x}" ] && present+=("$name")
done

have_systemd=0
if command -v systemctl >/dev/null 2>&1 && systemctl --user show-environment >/dev/null 2>&1; then
  have_systemd=1
fi

if [ "${1:-}" = --clear ]; then
  # Only clear the values if they still belong to this instance. Another
  # session may have published its own environment in the meantime.
  if [ "$have_systemd" = 1 ]; then
    current=$(systemctl --user show-environment 2>/dev/null | sed -n 's/^WAYLAND_DISPLAY=//p') || true
    if [ -n "$current" ] && [ "$current" = "${WAYLAND_DISPLAY:-}" ]; then
      systemctl --user unset-environment "${VARS[@]}" 2>/dev/null || true
    fi
  fi
  exit 0
fi

if [ "$have_systemd" = 1 ] && [ "${#present[@]}" -gt 0 ]; then
  systemctl --user import-environment "${present[@]}" 2>/dev/null || true
fi

# libdbus falls back to X11 when no bus address is available. Besides being
# wrong, DISPLAY might name an Xwayland this compositor has not started yet.
if [ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ] && [ -S "${XDG_RUNTIME_DIR:-}/bus" ]; then
  export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"
fi
if [ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ] &&
  command -v dbus-update-activation-environment >/dev/null 2>&1 &&
  [ "${#present[@]}" -gt 0 ]; then
  dbus-update-activation-environment "${present[@]}" 2>/dev/null || true
fi

# Portals are usually still running from the previous session. Restart the
# ones that are active so they reconnect to this compositor; later D-Bus
# activation then uses the corrected environment.
if [ "$have_systemd" = 1 ]; then
  systemctl --user reset-failed xdg-desktop-portal-hyprland.service 2>/dev/null || true
  systemctl --user try-restart xdg-desktop-portal.service 2>/dev/null || true
  systemctl --user try-restart xdg-desktop-portal-hyprland.service 2>/dev/null || true
fi
