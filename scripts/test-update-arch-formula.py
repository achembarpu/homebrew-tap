#!/usr/bin/env python3
"""Run the updater against temporary formulae and fake GitHub responses."""

import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest


ROOT = Path(__file__).resolve().parent.parent


class UpdateArchFormulaTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory(prefix="arch-formula-test-")
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "scripts").mkdir()
        (self.root / "Formula").mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        shutil.copy2(ROOT / "scripts/update-arch-formula.sh", self.root / "scripts")
        for formula, version in [("qwen-code", "0.24.0"), ("maki", "0.5.0")]:
            text = (ROOT / "Formula" / f"{formula}.rb").read_text()
            text = re.sub(r"/v[\d.]+/", f"/v{version}/", text)
            text = re.sub(r"-v[\d.]+-", f"-v{version}-", text)
            (self.root / "Formula" / f"{formula}.rb").write_text(text)
        self.fixture = {"tags": [], "responses": {}}
        self.requests = self.root / "requests.jsonl"
        self.env = os.environ.copy()
        for key in ("GH_TOKEN", "GITHUB_TOKEN"):
            self.env.pop(key, None)
        self.env.update(
            PATH=f"{self.bin}{os.pathsep}{self.env['PATH']}",
            ARCH_TEST_FIXTURE=str(self.root / "fixture.json"),
            ARCH_TEST_REQUESTS=str(self.requests),
        )
        self.write_tool("git", """
import json, os, sys
fixture = json.load(open(os.environ['ARCH_TEST_FIXTURE']))
assert sys.argv[1:4] == ['ls-remote', '--tags', '--refs'], sys.argv
assert sys.argv[-1] == 'v*', sys.argv
with open(os.environ['ARCH_TEST_REQUESTS'], 'a') as log:
    log.write(json.dumps(['git', *sys.argv[1:]]) + '\\n')
if fixture.get('git_error'):
    sys.exit(fixture['git_error'])
for tag in fixture['tags']:
    print('a' * 40 + '\\trefs/tags/' + tag)
""")
        self.write_tool("curl", """
import json, os, sys
fixture = json.load(open(os.environ['ARCH_TEST_FIXTURE']))
args = sys.argv[1:]
url = next(arg for arg in args if arg.startswith('https://'))
with open(os.environ['ARCH_TEST_REQUESTS'], 'a') as log:
    log.write(json.dumps(['curl', url]) + '\\n')
response = fixture['responses'].get(url)
if response is None:
    raise SystemExit('Unexpected request: ' + url)
status = response.get('status', 200)
if '-w' in args:
    print(status, end='')
if status >= 400:
    sys.exit(22)
if response.get('error'):
    sys.exit(response['error'])
content = response.get('content')
if content is None:
    content = json.dumps(response['json'])
with open(args[args.index('-o') + 1], 'w') as output:
    output.write(content)
""")

    def write_tool(self, name, source):
        path = self.bin / name
        path.write_text(f"#!{sys.executable}\n{source}")
        path.chmod(0o755)

    def release(self, version, formula="qwen-code", **overrides):
        repo = "QwenLM/qwen-code" if formula == "qwen-code" else "tontinton/maki"
        names = (
            ["qwen-code-darwin-arm64.tar.gz", "qwen-code-darwin-x64.tar.gz"]
            if formula == "qwen-code"
            else [f"maki-v{version}-aarch64-apple-darwin.tar.gz",
                  f"maki-v{version}-x86_64-apple-darwin.tar.gz"]
        )
        assets = []
        for architecture, name in zip(("arm", "intel"), names):
            url = f"https://github.com/{repo}/releases/download/v{version}/{name}"
            assets.append({"name": name, "browser_download_url": url})
            self.fixture["responses"][url] = {"content": f"{version}-{architecture}"}
        release = {"tag_name": f"v{version}", "draft": False,
                   "prerelease": False, "assets": assets}
        release.update(overrides)
        self.fixture["responses"][f"https://api.github.com/repos/{repo}/releases/tags/v{version}"] = {
            "json": release,
        }
        return release

    def run_updater(self, formula="qwen-code", dry_run=True):
        (self.root / "fixture.json").write_text(json.dumps(self.fixture))
        command = ["bash", str(self.root / "scripts/update-arch-formula.sh"), formula]
        if dry_run:
            command.append("--dry-run")
        return subprocess.run(command, env=self.env, capture_output=True, text=True, timeout=15)

    def calls(self):
        return [json.loads(line) for line in self.requests.read_text().splitlines()]

    def assert_no_update(self, tags, current="0.24.0"):
        self.fixture["tags"] = tags
        path = self.root / "Formula/qwen-code.rb"
        path.write_text(path.read_text().replace("/v0.24.0/", f"/v{current}/"))
        before = path.read_bytes()
        for dry_run in (True, False):
            result = self.run_updater(dry_run=dry_run)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertIn(f"already up to date: {current}", result.stdout)
            self.assertNotIn("Plan:", result.stdout)
            self.assertEqual(path.read_bytes(), before)
        self.assertTrue(all(call[0] == "git" for call in self.calls()))

    def test_older_release_cannot_downgrade(self):
        self.assert_no_update(["v0.21.2"], current="0.25.0")

    def test_equal_version_is_unchanged(self):
        self.assert_no_update(["v0.24.0"])

    def test_other_products_and_preview_tags_are_ignored(self):
        self.assert_no_update(["desktop-v9.0.0", "sdk-typescript-v9.0.0",
                               "v9.0.0-preview.0", "v9.0.0-nightly.20261007", "vlatest"])

    def test_numeric_order_and_release_lookup_without_release_list(self):
        self.fixture["tags"] = ["v0.25.0", "v0.9.0", "v0.100.0", "v0.26.0"]
        self.release("0.100.0")
        before = (self.root / "Formula/qwen-code.rb").read_bytes()
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("version: 0.24.0 -> 0.100.0", result.stdout)
        self.assertEqual(self.calls()[-1], ["curl", "https://api.github.com/repos/QwenLM/qwen-code/releases/tags/v0.100.0"])
        self.assertEqual(len(self.calls()), 2)
        self.assertEqual((self.root / "Formula/qwen-code.rb").read_bytes(), before)

    def test_unpublished_tag_is_skipped(self):
        self.fixture["tags"] = ["v0.26.0", "v0.25.0"]
        self.fixture["responses"]["https://api.github.com/repos/QwenLM/qwen-code/releases/tags/v0.26.0"] = {"status": 404}
        self.release("0.25.0")
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("version: 0.24.0 -> 0.25.0", result.stdout)

    def test_ineligible_newer_releases_are_skipped(self):
        self.fixture["tags"] = ["v0.29.0", "v0.28.0", "v0.27.0", "v0.26.0", "v0.25.0"]
        self.release("0.29.0", draft=True)
        self.release("0.28.0", prerelease=True)
        self.release("0.27.0", tag_name="desktop-v0.27.0")
        incomplete = self.release("0.26.0")
        incomplete["assets"].pop()
        self.release("0.25.0")
        result = self.run_updater()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("version: 0.24.0 -> 0.25.0", result.stdout)

    def test_only_ineligible_newer_releases_leave_pin_unchanged(self):
        self.fixture["tags"] = ["v0.25.0"]
        self.release("0.25.0", prerelease=True)
        before = (self.root / "Formula/qwen-code.rb").read_bytes()
        result = self.run_updater(dry_run=False)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("already up to date", result.stdout)
        self.assertEqual((self.root / "Formula/qwen-code.rb").read_bytes(), before)

    def test_both_formulas_update_both_urls_and_checksums(self):
        for formula, version in [("qwen-code", "0.25.0"), ("maki", "0.6.0")]:
            with self.subTest(formula=formula):
                self.fixture["tags"] = [f"v{version}"]
                release = self.release(version, formula=formula)
                path = self.root / "Formula" / f"{formula}.rb"
                before = path.read_text()
                result = self.run_updater(formula, dry_run=False)
                self.assertEqual(result.returncode, 0, result.stderr)
                after = path.read_text()
                for architecture, asset in zip(("arm", "intel"), release["assets"]):
                    digest = hashlib.sha256(f"{version}-{architecture}".encode()).hexdigest()
                    self.assertIn(f'url "{asset["browser_download_url"]}"\n    sha256 "{digest}"', after)
                self.assertEqual(before[before.index('  license '):], after[after.index('  license '):])

    def test_git_and_http_errors_propagate_without_writing(self):
        path = self.root / "Formula/qwen-code.rb"
        before = path.read_bytes()
        self.fixture["git_error"] = 128
        result = self.run_updater(dry_run=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(path.read_bytes(), before)
        del self.fixture["git_error"]
        self.fixture["tags"] = ["v0.25.0"]
        url = "https://api.github.com/repos/QwenLM/qwen-code/releases/tags/v0.25.0"
        for response in ({"status": 403}, {"status": 500}, {"error": 7}):
            with self.subTest(response=response):
                self.fixture["responses"][url] = response
                result = self.run_updater(dry_run=False)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn("already up to date", result.stdout)
                self.assertEqual(path.read_bytes(), before)

    def test_failed_second_download_does_not_partially_rewrite_formula(self):
        self.fixture["tags"] = ["v0.25.0"]
        release = self.release("0.25.0")
        self.fixture["responses"][release["assets"][1]["browser_download_url"]] = {"error": 7}
        path = self.root / "Formula/qwen-code.rb"
        before = path.read_bytes()
        result = self.run_updater(dry_run=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(path.read_bytes(), before)


if __name__ == "__main__":
    unittest.main(verbosity=2)
