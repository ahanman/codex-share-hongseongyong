#!/usr/bin/env python3
"""Exercise the portable installer only in temporary directories (stdlib)."""

import contextlib
import importlib.util
import io
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location("install_skills", Path(__file__).with_name("install-skills.py"))
INSTALLER = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(INSTALLER)


class InstallerTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="codex-skills-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def snapshot(self):
        package = self.root / "package"
        shutil.copytree(REPO / "skills", package / "skills")
        (package / "inventory").mkdir()
        shutil.copy2(REPO / "inventory" / "skills.json", package / "inventory" / "skills.json")
        return package

    def change_manifest(self, package, mutate):
        path = package / "inventory" / "skills.json"
        data = json.loads(path.read_text(encoding="utf-8-sig"))
        mutate(data)
        path.write_text(json.dumps(data), encoding="utf-8")

    def directory_link(self, target, link):
        try:
            os.symlink(target, link, target_is_directory=True)
            return
        except OSError:
            if os.name == "nt":
                result = subprocess.run(
                    ["cmd", "/c", "mklink", "/J", str(link), str(target)],
                    capture_output=True,
                )
                if result.returncode == 0:
                    return
            self.skipTest("Creating directory links is unavailable for this account.")

    def test_all_skills_and_existing_edits_are_preserved(self):
        target = self.root / "installed"
        result = INSTALLER.install(REPO, target)
        self.assertEqual(result["installedOrPlanned"], 293)
        manifest = json.loads((REPO / "inventory" / "skills.json").read_text(encoding="utf-8-sig"))
        checked = 0
        for skill in manifest["userSkills"]:
            for record in skill["files"]:
                self.assertEqual(INSTALLER.digest(target / skill["name"] / record["path"]), record["sha256"].lower())
                checked += 1
        self.assertEqual(checked, 591)
        edited = target / "accessibility" / "SKILL.md"
        edited.write_text("Keep this user's existing work.", encoding="utf-8")
        again = INSTALLER.install(REPO, target)
        self.assertEqual(again["installedOrPlanned"], 0)
        self.assertEqual(again["skippedExisting"], 293)
        self.assertEqual(edited.read_text(encoding="utf-8"), "Keep this user's existing work.")

    def test_preview_and_selection(self):
        target = self.root / "selected"
        with contextlib.redirect_stdout(io.StringIO()):
            preview = INSTALLER.install(REPO, target, ["accessibility"], dry_run=True)
        self.assertEqual(preview["installedOrPlanned"], 1)
        self.assertFalse(target.exists())
        result = INSTALLER.install(REPO, target, ["accessibility", "api-design"])
        self.assertEqual(result["installedOrPlanned"], 2)
        self.assertEqual({entry.name for entry in target.iterdir()}, {"accessibility", "api-design"})

    def test_unknown_selection_writes_nothing(self):
        target = self.root / "unknown"
        with self.assertRaises(INSTALLER.PackageError):
            INSTALLER.install(REPO, target, ["missing-skill"])
        self.assertFalse(target.exists())

    def test_tampering_fails_before_any_target_writes(self):
        package = self.snapshot()
        (package / "skills" / "codex" / "api-design" / "SKILL.md").write_text("tampered", encoding="utf-8")
        target = self.root / "tampered"
        with self.assertRaises(INSTALLER.PackageError):
            INSTALLER.install(package, target, ["accessibility"])
        self.assertFalse(target.exists())

    def test_unsafe_source_and_file_paths_fail_before_writes(self):
        package = self.snapshot()
        manifest = package / "inventory" / "skills.json"
        original = manifest.read_bytes()
        for key, value in (("repositoryPath", "skills/../../outside"), ("filePath", "../SKILL.md"), ("filePath", "C:/outside")):
            with self.subTest(key=key, value=value):
                manifest.write_bytes(original)
                if key == "filePath":
                    self.change_manifest(package, lambda data: data["userSkills"][0]["files"][0].update(path=value))
                else:
                    self.change_manifest(package, lambda data: data["userSkills"][0].update(repositoryPath=value))
                target = self.root / "unsafe"
                with self.assertRaises(INSTALLER.PackageError):
                    INSTALLER.install(package, target)
                self.assertFalse(target.exists())

    def test_existing_destination_file_stops_before_install(self):
        target = self.root / "file-conflict"
        target.mkdir()
        (target / "api-design").write_text("preserve", encoding="utf-8")
        with self.assertRaises(INSTALLER.PackageError):
            INSTALLER.install(REPO, target)
        self.assertEqual({entry.name for entry in target.iterdir()}, {"api-design"})

    def test_linked_destination_is_rejected(self):
        target = self.root / "linked-target"
        target.mkdir()
        outside = self.root / "outside"
        outside.mkdir()
        self.directory_link(outside, target / "api-design")
        with self.assertRaises(INSTALLER.PackageError):
            INSTALLER.install(REPO, target)
        self.assertEqual(list(outside.iterdir()), [])

    def test_linked_package_content_is_rejected(self):
        package = self.snapshot()
        outside = self.root / "outside-source"
        outside.mkdir()
        self.directory_link(outside, package / "skills" / "codex" / "accessibility" / "linked-content")
        target = self.root / "source-link-install"
        with self.assertRaises(INSTALLER.PackageError):
            INSTALLER.install(package, target)
        self.assertFalse(target.exists())


if __name__ == "__main__":
    unittest.main(verbosity=2)
