#!/usr/bin/env python3
"""Install the verified skill snapshot without running any bundled skill code."""

import argparse
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import shutil
import stat
import sys


class PackageError(ValueError):
    """The package or installation destination is unsafe or incomplete."""


def is_link(path):
    """Include Windows junctions and other reparse points, even on Python 3.9."""
    info = path.lstat()
    return stat.S_ISLNK(info.st_mode) or bool(
        getattr(info, "st_file_attributes", 0)
        & getattr(stat, "FILE_ATTRIBUTE_REPARSE_POINT", 0x400)
    )


def relative_path(value):
    if not isinstance(value, str) or not value or "\\" in value or ":" in value:
        raise PackageError("Invalid package path.")
    parts = value.split("/")
    if any(part in ("", ".", "..") for part in parts):
        raise PackageError("A package path is absolute or leaves its directory.")
    path = PurePosixPath(value)
    if path.is_absolute():
        raise PackageError("Absolute package paths are not allowed.")
    return Path(*parts)


def reject_links_between(root, path):
    current = root
    if is_link(current):
        raise PackageError("Linked package directories are not allowed: " + str(current))
    for part in path.relative_to(root).parts:
        current = current / part
        if is_link(current):
            raise PackageError("Linked package files are not allowed: " + str(current))


def digest(path):
    result = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            result.update(block)
    return result.hexdigest()


def verified_skills(repo_root):
    """Validate the whole manifest and all source files before any target writes."""
    repo_root = Path(repo_root).resolve()
    manifest_path = repo_root / "inventory" / "skills.json"
    reject_links_between(repo_root, manifest_path)
    manifest = json.loads(manifest_path.read_text(encoding="utf-8-sig"))
    skills = manifest.get("userSkills")
    if (
        manifest.get("schemaVersion") != 1
        or not isinstance(skills, list)
        or not skills
        or manifest.get("expectedUserSkillCount") != len(skills)
    ):
        raise PackageError("The skills manifest is invalid or incomplete.")
    skills_root = repo_root / "skills"
    names = set()
    verified = []
    for skill in skills:
        name = skill.get("name", "")
        if not isinstance(name, str) or not re.fullmatch(r"[a-z0-9][a-z0-9._-]*", name) or name in names:
            raise PackageError("The manifest contains an unsafe or duplicate skill name.")
        names.add(name)
        source = repo_root / relative_path(skill.get("repositoryPath"))
        if skills_root not in source.parents or source.name != name:
            raise PackageError("A skill source leaves the repository skills directory.")
        reject_links_between(repo_root, source)
        if not source.is_dir():
            raise PackageError("A skill source is not a regular directory: " + name)
        actual = set()
        for directory, directories, files in os.walk(source, followlinks=False):
            for entry_name in directories + files:
                entry = Path(directory) / entry_name
                if is_link(entry):
                    raise PackageError("A skill contains linked files: " + name)
                if entry.is_file():
                    actual.add(entry.relative_to(source).as_posix())
                elif not entry.is_dir():
                    raise PackageError("A skill contains an unsupported file: " + name)
        records = skill.get("files")
        if not isinstance(records, list) or skill.get("fileCount") != len(records):
            raise PackageError("A skill file count is invalid: " + name)
        declared = set()
        portable_names = set()
        for record in records:
            relative = relative_path(record.get("path"))
            relative_name = relative.as_posix()
            if relative_name.casefold() in portable_names:
                raise PackageError("A skill has duplicate file paths: " + name)
            portable_names.add(relative_name.casefold())
            declared.add(relative_name)
            expected = record.get("sha256", "")
            if not isinstance(expected, str) or not re.fullmatch(r"[0-9a-fA-F]{64}", expected):
                raise PackageError("A skill checksum is invalid: " + name)
            file_path = source / relative
            if not file_path.is_file() or digest(file_path) != expected.lower():
                raise PackageError("A skill file failed its SHA-256 check: " + name + "/" + relative_name)
        if actual != declared or "SKILL.md" not in actual:
            raise PackageError("A skill source has missing or unexpected files: " + name)
        verified.append((name, source))
    return verified


def install(repo_root, target_root=None, selected=None, dry_run=False):
    skills = verified_skills(repo_root)
    requested = set(selected or [])
    known = {name for name, _ in skills}
    unknown = requested - known
    if unknown:
        raise PackageError("Unknown skill name(s): " + ", ".join(sorted(unknown)))
    if requested:
        skills = [(name, source) for name, source in skills if name in requested]
    target = Path(target_root) if target_root is not None else Path.home() / ".agents" / "skills"
    target = target.expanduser().absolute()
    if os.path.lexists(target) and (is_link(target) or not target.is_dir()):
        raise PackageError("The target must be a regular directory, not a link or file.")
    # Resolve parent aliases once; every destination below this root is checked.
    target = target.resolve()
    source_root = (Path(repo_root).resolve() / "skills")
    if target == source_root or source_root in target.parents or target in source_root.parents:
        raise PackageError("The installation target overlaps the package source.")
    plan = []
    skipped = 0
    for name, source in skills:
        destination = target / name
        if os.path.lexists(destination):
            if is_link(destination) or not destination.is_dir():
                raise PackageError("An existing skill destination is linked or not a directory: " + name)
            skipped += 1
        else:
            plan.append((name, source, destination))
    if not dry_run and plan:
        target.mkdir(parents=True, exist_ok=True)
    for name, source, destination in plan:
        if dry_run:
            print("PREVIEW install " + name)
        else:
            # copytree refuses existing destinations; never merge into user data.
            shutil.copytree(source, destination)
    return {
        "mode": "preview" if dry_run else "install",
        "selected": len(skills),
        "installedOrPlanned": len(plan),
        "skippedExisting": skipped,
        "targetRoot": str(target),
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--target-root", type=Path, help="default: ~/.agents/skills")
    parser.add_argument("--dry-run", action="store_true", help="verify and preview without writing")
    parser.add_argument("--skill", action="append", default=[], metavar="NAME", help="install only this skill (repeat for more)")
    args = parser.parse_args()
    try:
        result = install(Path(__file__).resolve().parent.parent, args.target_root, args.skill, args.dry_run)
    except (PackageError, OSError, ValueError, TypeError, KeyError) as error:
        print("Installation stopped: " + str(error), file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2))
    print("Open a new Codex turn to use the skills. If they do not appear, restart Codex.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
