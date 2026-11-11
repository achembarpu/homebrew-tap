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
    def run_update(self, feed, binary, folder=None, current="1.44a", *args, probe_mode="ok", probe_version=""):
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
            # Exercise the shell workflow separately from the HTTP range reader,
            # which has its own tests with simulated range responses.
            (root / "scripts/probe-optcgsim.py").write_text(
                'import os, re, sys, zipfile\n'
                'mode = os.environ["PROBE_MODE"]\n'
                'if mode == "fail-all" or (mode == "fail-dropbox" and "dropbox" in sys.argv[1]): sys.exit(1)\n'
                'with zipfile.ZipFile(os.path.join(os.environ["FIXTURES"], "archive")) as z:\n'
                '    name = next(n for n in z.namelist() if n.endswith("Assembly-CSharp.dll"))\n'
                '    match = re.search(rb"sim version:\\s*([0-9]+\\.[0-9]+[a-z]*)", z.read(name).replace(b"\\x00", b""))\n'
                '    version = match.group(1).decode()\n'
                '    if not name.startswith(f"{version}_Mac/OPTCGSim.app/"): sys.exit(1)\n'
                '    print(f"{os.environ[\'PROBE_VERSION\'] or version}\\t123")\n'
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
                '[ "$source" != archive ] || touch "$FIXTURES/downloaded"\n'
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
                "PROBE_MODE": probe_mode,
                "PROBE_VERSION": probe_version,
            }
            result = subprocess.run(
                ["bash", str(root / "scripts/update-optcgsim.sh"), *args],
                env=env,
                text=True,
                capture_output=True,
            )
            result.downloaded_archive = (root / "downloaded").exists()
            return result, (root / "Casks/optcgsim.rb").read_text()

    def test_newer_archive_is_used_when_feed_lags(self):
        result, cask = self.run_update("1.44a", "1.45a")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('version "1.45a"', cask)
        self.assertTrue(result.downloaded_archive)

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
        self.assertFalse(result.downloaded_archive)

    def test_current_archive_does_not_write(self):
        result, cask = self.run_update("1.44a", "1.45a", None, "1.45a")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already up to date", result.stdout)
        self.assertIn('sha256 "old"', cask)
        self.assertFalse(result.downloaded_archive)

    def test_google_drive_is_used_if_dropbox_range_fails(self):
        result, cask = self.run_update("1.44a", "1.45a", probe_mode="fail-dropbox")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('version "1.45a"', cask)
        self.assertIn("drive.usercontent.google.com", cask)

    def test_failed_range_inspections_do_not_download_the_archive(self):
        result, cask = self.run_update("1.44a", "1.45a", probe_mode="fail-all")
        self.assertEqual(result.returncode, 75, result.stderr)
        self.assertIn('version "1.44a"', cask)
        self.assertFalse(result.downloaded_archive)

    def test_archive_changing_after_probe_is_rejected(self):
        result, cask = self.run_update("1.44a", "1.45a", probe_version="1.46")
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('version "1.44a"', cask)
        self.assertTrue(result.downloaded_archive)


if __name__ == "__main__":
    unittest.main()
