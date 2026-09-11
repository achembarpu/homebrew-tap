#!/usr/bin/env bash
set -euo pipefail

# Update a formula whose macOS release has separate arm64 and x86_64 assets.
# Homebrew's generic bump command cannot rewrite both conditional URL stanzas.
# The script never commits; commit the formula separately.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORMULA="${1:-}"
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: update-arch-formula.sh <formula> [--dry-run]

Supported formulas: qwen-code, maki.
EOF
}

if [[ "$FORMULA" == "-h" || "$FORMULA" == "--help" ]]; then usage; exit 0; fi
[[ "$FORMULA" == "qwen-code" || "$FORMULA" == "maki" ]] || { usage >&2; exit 1; }
if [[ "${2:-}" == "--dry-run" ]]; then DRY_RUN=1; elif [[ -n "${2:-}" ]]; then usage >&2; exit 1; fi

case "$FORMULA" in
  qwen-code) REPO="QwenLM/qwen-code" ;;
  maki) REPO="tontinton/maki" ;;
esac

FORMULA_FILE="$ROOT_DIR/Formula/$FORMULA.rb"
[[ -f "$FORMULA_FILE" ]] || { printf 'Error: formula not found: %s\n' "$FORMULA_FILE" >&2; exit 1; }
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
API_ARGS=(-fsSL --retry 3 --connect-timeout 15 -H 'Accept: application/vnd.github+json')
[[ -n "$TOKEN" ]] && API_ARGS+=(-H "Authorization: Bearer $TOKEN")
curl "${API_ARGS[@]}" "https://api.github.com/repos/$REPO/releases?per_page=100" -o "$TMP_DIR/releases.json"

RELEASE_META="$(python3 - "$TMP_DIR/releases.json" "$FORMULA" <<'PY'
import json, re, sys
releases = json.load(open(sys.argv[1]))
formula = sys.argv[2]

if formula == "maki":
    asset_names = lambda version: (
        f"maki-v{version}-aarch64-apple-darwin.tar.gz",
        f"maki-v{version}-x86_64-apple-darwin.tar.gz",
    )
else:
    asset_names = lambda version: (
        "qwen-code-darwin-arm64.tar.gz",
        "qwen-code-darwin-x64.tar.gz",
    )

# The repository publishes SDK, desktop, and CLI releases.  Do not use
# /releases/latest: GitHub considers the most recently published release
# "latest", even when it is for a different product.
for release in releases:
    if release.get("draft") or release.get("prerelease"):
        continue
    tag = release.get("tag_name", "")
    match = re.fullmatch(r"v(\d+(?:\.\d+)+)", tag)
    if not match:
        continue
    version = match.group(1)
    names = {a["name"]: a["browser_download_url"] for a in release.get("assets", [])}
    arm, intel = asset_names(version)
    if arm in names and intel in names:
        print(version, names[arm], names[intel])
        break
else:
    raise SystemExit("could not find a stable release with both macOS architecture assets")
PY
)"
read -r TARGET_VERSION ARM_URL INTEL_URL <<< "$RELEASE_META"

CURRENT_VERSION="$(python3 - "$FORMULA_FILE" <<'PY'
import re, sys
text = open(sys.argv[1]).read()
m = re.search(r'/releases/download/v([^/"?]+)/', text)
print(m.group(1) if m else "")
PY
)"
[[ -n "$CURRENT_VERSION" ]] || { printf 'Error: could not read current version from release URL\n' >&2; exit 1; }
if [[ "$TARGET_VERSION" == "$CURRENT_VERSION" ]]; then
  printf '%s already up to date: %s\n' "$FORMULA" "$CURRENT_VERSION"
  exit 0
fi

printf 'Plan:\n  formula: %s\n  version: %s -> %s\n  arm64:   %s\n  x86_64:  %s\n' "$FORMULA" "$CURRENT_VERSION" "$TARGET_VERSION" "$ARM_URL" "$INTEL_URL"
[[ "$DRY_RUN" == 1 ]] && exit 0

curl "${API_ARGS[@]}" "$ARM_URL" -o "$TMP_DIR/arm.tar.gz"
curl "${API_ARGS[@]}" "$INTEL_URL" -o "$TMP_DIR/intel.tar.gz"
ARM_SHA="$(shasum -a 256 "$TMP_DIR/arm.tar.gz" | awk '{print $1}')"
INTEL_SHA="$(shasum -a 256 "$TMP_DIR/intel.tar.gz" | awk '{print $1}')"

python3 - "$FORMULA_FILE" "$CURRENT_VERSION" "$TARGET_VERSION" "$ARM_URL" "$INTEL_URL" "$ARM_SHA" "$INTEL_SHA" <<'PY'
import pathlib, re, sys
path = pathlib.Path(sys.argv[1])
text = path.read_text()
old, new, arm_url, intel_url, arm_sha, intel_sha = sys.argv[2:]
text = text.replace(f'/v{old}/', f'/v{new}/')
text = text.replace(f'-v{old}-', f'-v{new}-')
lines = text.splitlines(keepends=True)
branch = "arm"
for i, line in enumerate(lines):
    if line.strip() == "license \"Apache-2.0\"" or line.strip() == "license \"MIT\"": break
    if line.strip() == "else": branch = "intel"
    if re.match(r'\s+url "', line): lines[i] = re.sub(r'url "[^"]+"', f'url "{arm_url if branch == "arm" else intel_url}"', line)
    elif re.match(r'\s+sha256 "', line): lines[i] = re.sub(r'sha256 "[^"]+"', f'sha256 "{arm_sha if branch == "arm" else intel_sha}"', line)
path.write_text(''.join(lines))
PY
