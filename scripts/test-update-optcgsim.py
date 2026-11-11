#!/usr/bin/env python3
"""Exercise version discovery using small, local stand-ins for the downloads."""

import os
import shutil
import subprocess
import tempfile
import unittest
import zipfile
from pathlib import Path


SCRIPT = Path(__file__).with_name("update-optcgsim.sh")


class UpdateOptcgsimTest(unittest.TestCase):
    def run_update(self, feed, binary, folder=None, current="1.44a", *args):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "scripts").mkdir()
            (root / "Casks").mkdir()
            (root / "bin").mkdir()
            shutil.copy(SCRIPT, root / "scripts/update-optcgsim.sh")
            (root / "Casks/optcgsim.rb").write_text(
                f'  version "{current}"\n  sha256 "old"\n  url "old",\n'
            )
            (root / "feed").write_text(f"<item><title>{feed} Release</title></item>")
            (root / "page").write_text(
                'aria-labelledby="mac" '
                'href="https://www.dropbox.com/scl/fi/abc/1_30d_Mac.zip?dl=1" '
                'href="https://drive.google.com/file/d/abc/view"'
            )
            with zipfile.ZipFile(root / "archive", "w") as archive:
                prefix = f"{folder or binary}_Mac/OPTCGSim.app/"
                archive.writestr(prefix + "Contents/", "")
                archive.writestr(
                    prefix + "Contents/Assembly-CSharp.dll",
                    f"sim version: {binary}".encode("utf-16le"),
                )
            curl = root / "bin/curl"
            curl.write_text(
                '#!/bin/bash\n'
                'while [ "$#" -gt 0 ]; do\n'
                '  case "$1" in -o) out="$2"; shift 2;; '
                'https://*) url="$1"; shift;; *) shift;; esac\n'
                'done\n'
                'case "$url" in */feed/) source=feed;; '
                'https://optcgsim.com/) source=page;; *) source=archive;; esac\n'
                'cp "$FIXTURES/$source" "$out"\n'
            )
            curl.chmod(0o755)
            brew = root / "bin/brew"
            brew.write_text("#!/bin/bash\nexit 0\n")
            brew.chmod(0o755)
            env = os.environ | {
                "PATH": str(root / "bin") + ":" + os.environ["PATH"],
                "FIXTURES": str(root),
                "TAP_CASK": str(root / "missing-tap"),
            }
            result = subprocess.run(
                ["bash", str(root / "scripts/update-optcgsim.sh"), *args],
                env=env,
                text=True,
                capture_output=True,
            )
            return result, (root / "Casks/optcgsim.rb").read_text()

    def test_newer_archive_is_used_when_feed_lags(self):
        result, cask = self.run_update("1.44a", "1.45a")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('version "1.45a"', cask)

    def test_feed_newer_than_archive_is_rejected(self):
        result, cask = self.run_update("1.46", "1.45a")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('version "1.44a"', cask)

    def test_mismatched_bundle_path_is_rejected(self):
        result, cask = self.run_update("1.44a", "1.45a", "1.45")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('version "1.44a"', cask)

    def test_download_cannot_downgrade_cask(self):
        result, cask = self.run_update("1.44a", "1.45a", None, "1.46")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('version "1.46"', cask)

    def test_override_requires_exact_binary_version(self):
        result, cask = self.run_update("1.44a", "1.45a", None, "1.44a", "--version", "1.45")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('version "1.44a"', cask)

    def test_dry_run_discovers_without_writing(self):
        result, cask = self.run_update("1.44a", "1.45a", None, "1.44a", "--dry-run")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("new version: 1.45a", result.stdout)
        self.assertIn('version "1.44a"', cask)

    def test_current_archive_does_not_write(self):
        result, cask = self.run_update("1.44a", "1.45a", None, "1.45a")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already up to date", result.stdout)
        self.assertIn('sha256 "old"', cask)


if __name__ == "__main__":
    unittest.main()
