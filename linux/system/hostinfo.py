#!/usr/bin/env python3
"""Resolve machine profiles and configuration layers.

This module is shared by apply.py, 2-install_packages.sh, setup.sh, and
3-post_installation.sh. It reads the same host data that chezmoi uses.
"""
from __future__ import annotations

import argparse
import os
import shlex
import socket
import sys
import tomllib
from pathlib import Path

LINUX = Path(__file__).resolve().parent.parent
HOSTS_FILE = LINUX / "chezmoi" / ".chezmoidata" / "hosts.toml"

FORM_VALUES = ("laptop", "desktop")
CPU_VALUES = ("amd", "intel")

CHASSIS_LAPTOP = {8, 9, 10, 14}
CHASSIS_DESKTOP = {3, 4, 5, 6, 7, 13, 15, 16, 17, 23, 24}


def die(message: str) -> "NoReturn":
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(2)


def load_hosts() -> dict[str, dict]:
    try:
        with HOSTS_FILE.open("rb") as fh:
            data = tomllib.load(fh)
    except OSError as exc:
        die(f"cannot read {HOSTS_FILE}: {exc}")
    except tomllib.TOMLDecodeError as exc:
        die(f"invalid TOML in {HOSTS_FILE}: {exc}")
    return data.get("hosts", {})


def _override(value: str | None) -> str | None:
    if value in (None, "", "auto"):
        return None
    return value


def detect_form(explicit: str | None = None) -> str:
    value = _override(explicit) or _override(os.environ.get("CONFIG_FORM"))
    if value:
        if value not in FORM_VALUES:
            die(f"invalid form {value!r}; expected one of {', '.join(FORM_VALUES)}")
        return value

    try:
        chassis = int(Path("/sys/class/dmi/id/chassis_type").read_text().strip())
    except (OSError, ValueError):
        chassis = None

    if chassis in CHASSIS_LAPTOP:
        return "laptop"
    if chassis in CHASSIS_DESKTOP:
        return "desktop"

    power_supply = Path("/sys/class/power_supply")
    if power_supply.is_dir() and any(power_supply.glob("BAT*")):
        return "laptop"
    if list(Path("/sys/class/drm").glob("*-eDP-*")):
        return "laptop"

    return "desktop"


def detect_cpu(explicit: str | None = None) -> str:
    value = _override(explicit) or _override(os.environ.get("CONFIG_CPU"))
    if value:
        if value not in CPU_VALUES:
            die(f"invalid cpu {value!r}; expected one of {', '.join(CPU_VALUES)}")
        return value

    try:
        cpuinfo = Path("/proc/cpuinfo").read_text()
    except OSError as exc:
        die(f"cannot read /proc/cpuinfo: {exc}")

    if "AuthenticAMD" in cpuinfo or "AMD" in cpuinfo:
        return "amd"
    if "GenuineIntel" in cpuinfo or "Intel" in cpuinfo:
        return "intel"
    die("cannot detect CPU vendor; pass --cpu amd|intel")


def resolve(
    host: str | None = None,
    form: str | None = None,
    cpu: str | None = None,
) -> dict[str, object]:
    hosts = load_hosts()
    name = host or os.environ.get("CONFIG_HOST") or socket.gethostname().split(".")[0]
    if name not in hosts:
        die(f"unknown host {name!r}; add [hosts.{name}] to {HOSTS_FILE}")
    profile = hosts[name]

    form_value = _override(form) or _override(profile.get("form")) or detect_form()
    cpu_value = _override(cpu) or _override(profile.get("cpu")) or detect_cpu()

    compositor = profile.get("compositor")
    shell = profile.get("shell")
    roles = profile.get("roles") or []
    if not isinstance(compositor, str) or not compositor:
        die(f"[hosts.{name}] is missing compositor")
    if not isinstance(shell, str) or not shell:
        die(f"[hosts.{name}] is missing shell")
    if not isinstance(roles, list) or not all(isinstance(r, str) for r in roles):
        die(f"[hosts.{name}] roles must be a list of strings")

    return {
        "host": name,
        "form": form_value,
        "cpu": cpu_value,
        "compositor": compositor,
        "shell": shell,
        "roles": roles,
    }


def _existing(paths: list[Path]) -> list[Path]:
    return [path for path in paths if path.is_file()]


def package_paths(resolved: dict[str, object], mode: str) -> list[Path]:
    paths = [LINUX / "packages" / "common.md"]
    if mode == "install":
        paths.append(LINUX / "packages" / "install-only.md")
    paths.extend(
        [
            LINUX / "packages" / "form" / f"{resolved['form']}.md",
            LINUX / "packages" / "cpu" / f"{resolved['cpu']}.md",
            LINUX / "packages" / "compositor" / f"{resolved['compositor']}.md",
            LINUX / "packages" / "shell" / f"{resolved['shell']}.md",
        ]
    )
    paths.extend(
        LINUX / "packages" / "role" / f"{role}.md" for role in resolved["roles"]
    )
    paths.append(LINUX / "packages" / "host" / f"{resolved['host']}.md")
    return _existing(paths)


def manifest_paths(resolved: dict[str, object]) -> list[Path]:
    paths = [
        LINUX / "system" / "manifest.toml",
        LINUX / "system" / "manifests" / "form" / f"{resolved['form']}.toml",
        LINUX / "system" / "manifests" / "cpu" / f"{resolved['cpu']}.toml",
        LINUX / "system" / "manifests" / "compositor" / f"{resolved['compositor']}.toml",
        LINUX / "system" / "manifests" / "shell" / f"{resolved['shell']}.toml",
    ]
    paths.extend(
        LINUX / "system" / "manifests" / "role" / f"{role}.toml"
        for role in resolved["roles"]
    )
    return _existing(paths)


def print_shell_env(resolved: dict[str, object]) -> None:
    values = {
        "CONFIG_HOST": resolved["host"],
        "CONFIG_FORM": resolved["form"],
        "CONFIG_CPU": resolved["cpu"],
        "CONFIG_COMPOSITOR": resolved["compositor"],
        "CONFIG_SHELL": resolved["shell"],
        "CONFIG_ROLES": " ".join(resolved["roles"]),
    }
    for key, value in values.items():
        print(f"{key}={shlex.quote(str(value))}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--host")
    parser.add_argument("--form")
    parser.add_argument("--cpu")
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("shell-env")

    pkg_p = sub.add_parser("packages")
    pkg_p.add_argument("--mode", choices=("install", "sync"), default="sync")

    sub.add_parser("manifests")

    args = parser.parse_args()
    resolved = resolve(args.host, args.form, args.cpu)

    if args.command == "shell-env":
        print_shell_env(resolved)
    elif args.command == "packages":
        for path in package_paths(resolved, args.mode):
            print(path)
    elif args.command == "manifests":
        for path in manifest_paths(resolved):
            print(path)


if __name__ == "__main__":
    main()
