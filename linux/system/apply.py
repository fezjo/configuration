#!/usr/bin/env python3
"""File-only system manifest runner.

The manifest describes files and edits. Service activation and commands belong
in 3-post_installation.sh.
"""
from __future__ import annotations

import argparse
import difflib
import os
import re
import shutil
import sys
import tomllib
from datetime import datetime
from pathlib import Path

BASE = Path(__file__).resolve().parent
LINUX = BASE.parent
DEFAULT_MANIFEST = BASE / "manifest.toml"


def die(message: str) -> "NoReturn":
    print(f"error: {message}", file=sys.stderr)
    raise SystemExit(2)


def load_manifest(path: Path) -> dict:
    try:
        with path.open("rb") as fh:
            data = tomllib.load(fh)
    except (OSError, tomllib.TOMLDecodeError) as exc:
        die(f"cannot read {path}: {exc}")
    return data


def text_diff(old: str, new: str, fromfile: str, tofile: str) -> str:
    return "".join(
        difflib.unified_diff(
            old.splitlines(keepends=True),
            new.splitlines(keepends=True),
            fromfile=fromfile,
            tofile=tofile,
        )
    )


def read_text(path: Path) -> str | None:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None


def apply_edit(text: str, edit: dict) -> str:
    kind = edit.get("kind")
    file = edit.get("file", "<unknown>")
    if kind in ("option", "value"):
        pattern = re.compile(edit["match"])
        lines = text.splitlines(keepends=True)
        for i, line in enumerate(lines):
            if pattern.search(line):
                lines[i] = edit["value"] + ("\n" if line.endswith("\n") else "")
                return "".join(lines)
        if kind == "value":
            die(f"{file}: no line matches {edit['match']!r}")
        # Insert a missing option inside [options], or append as a last resort.
        for i, line in enumerate(lines):
            if line.strip() == "[options]":
                lines.insert(i + 1, edit["value"] + "\n")
                return "".join(lines)
        lines.append(edit["value"] + "\n")
        return "".join(lines)

    if kind == "section":
        name = edit["name"]
        include = edit["include"]
        header = re.compile(rf"^#?\[{re.escape(name)}\]\s*$")
        include_re = re.compile(r"^#?Include\s*=")
        lines = text.splitlines(keepends=True)
        out: list[str] = []
        found = False
        in_section = False
        include_done = False
        for line in lines:
            if header.match(line):
                out.append(f"[{name}]\n")
                found = True
                in_section = True
                continue
            if in_section and include_re.match(line):
                out.append(include + "\n")
                include_done = True
                in_section = False
                continue
            if in_section and line.startswith("[") and line.strip():
                if not include_done:
                    out.append(include + "\n")
                    include_done = True
                in_section = False
            out.append(line)
        if not found:
            out.extend(["\n", f"[{name}]\n", include + "\n"])
        elif not include_done:
            out.append(include + "\n")
        return "".join(out)

    die(f"{file}: unknown edit kind {kind!r}")


def file_state(entry: dict) -> tuple[bool, str, str | None]:
    """Return (changed, label, diff_or_none)."""
    src = LINUX / entry["src"]
    dest = Path(entry["dest"])
    mode = int(entry.get("mode", "0644"), 8)
    if not src.is_file():
        die(f"missing source {src}")

    dest_bytes = dest.read_bytes() if dest.is_file() else b""
    src_bytes = src.read_bytes()
    content_changed = dest_bytes != src_bytes
    mode_changed = dest.is_file() and (dest.stat().st_mode & 0o7777) != mode
    changed = content_changed or mode_changed
    if not changed:
        return False, f"{dest}", None

    old = read_text(dest) if dest.is_file() else ""
    new = read_text(src)
    if old is None or new is None:
        diff = f"Binary files {dest} and {src} differ\n"
    else:
        diff = text_diff(old, new, str(dest), str(src))
    if mode_changed:
        diff += f"mode: {oct(dest.stat().st_mode & 0o7777)} -> {oct(mode)}\n"
    return True, f"{dest}", diff


def edit_state(entry: dict) -> tuple[bool, str, str | None]:
    dest = Path(entry["file"])
    if not dest.is_file():
        die(f"missing target {dest}")
    old = read_text(dest)
    if old is None:
        die(f"cannot read {dest} as text")
    new = apply_edit(old, entry)
    changed = old != new
    if not changed:
        return False, f"{dest}", None
    return True, f"{dest}", text_diff(old, new, str(dest), str(dest) + " (desired)")


def collect(manifest: dict) -> list[tuple[str, bool, str, str | None]]:
    actions: list[tuple[str, bool, str, str | None]] = []
    for entry in manifest.get("file", []):
        changed, label, diff = file_state(entry)
        actions.append(("file", changed, label, diff))
    for entry in manifest.get("edit", []):
        changed, label, diff = edit_state(entry)
        actions.append(("edit", changed, label, diff))
    return actions


def backup(dest: Path, backup_root: Path) -> None:
    if not dest.exists():
        return
    target = backup_root / str(dest).lstrip("/").replace("/", "_")
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(dest, target)


def apply_actions(manifest: dict, backup_root: Path) -> int:
    changes = 0
    for entry in manifest.get("file", []):
        src = LINUX / entry["src"]
        dest = Path(entry["dest"])
        mode = int(entry.get("mode", "0644"), 8)
        changed, _, _ = file_state(entry)
        if not changed:
            continue
        changes += 1
        backup(dest, backup_root)
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src, dest)
        os.chmod(dest, mode)
        print(f"wrote {dest}")
    for entry in manifest.get("edit", []):
        dest = Path(entry["file"])
        changed, _, _ = edit_state(entry)
        if not changed:
            continue
        changes += 1
        backup(dest, backup_root)
        old_mode = dest.stat().st_mode & 0o7777
        text = read_text(dest)
        assert text is not None
        dest.write_text(apply_edit(text, entry), encoding="utf-8")
        os.chmod(dest, old_mode)
        print(f"edited {dest}")
    return changes


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--plan", action="store_true", help="show actions and status")
    group.add_argument("--diff", action="store_true", help="show unified diffs")
    group.add_argument("--check", action="store_true", help="exit 1 if changes are needed")
    group.add_argument("--apply", action="store_true", help="apply changes")
    parser.add_argument("--yes", "-y", action="store_true", help="do not prompt")
    parser.add_argument("--no-backup", action="store_true")
    args = parser.parse_args()

    if not (args.plan or args.diff or args.check or args.apply):
        args.plan = True

    manifest = load_manifest(args.manifest)
    actions = collect(manifest)
    changed = [a for a in actions if a[1]]

    if args.plan:
        for kind, is_changed, label, _ in actions:
            print(f"{'CHANGE' if is_changed else 'ok    '}  {kind:7}  {label}")
        print(f"\n{len(changed)} change(s)")
        return 0

    if args.diff:
        for _, is_changed, _, diff in actions:
            if is_changed and diff:
                print(diff, end="" if diff.endswith("\n") else "\n")
        print(f"{len(changed)} change(s)")
        return 0

    if args.check:
        print(f"{len(changed)} change(s)")
        return 1 if changed else 0

    if os.geteuid() != 0:
        die("--apply must run as root")

    if not changed:
        print("no changes")
        return 0

    if not args.yes:
        reply = input(f"Apply {len(changed)} change(s)? [y/N] ")
        if reply.lower() not in ("y", "yes"):
            die("aborted")

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_root = Path("/var/backups/configuration") / stamp
    count = apply_actions(manifest, backup_root)
    print(f"applied {count} change(s)")
    if not args.no_backup:
        print(f"backups: {backup_root}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
