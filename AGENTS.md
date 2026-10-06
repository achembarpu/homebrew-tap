# homebrew-tap — agent guide

Personal Homebrew tap for apps and CLI tools without an official Homebrew package. **The cask/formula file is
the contract**: each cask and formula pins an exact `version` + `sha256` and wraps a
specific upstream artifact (normally a GitHub release asset). No `:no_check`, no rolling URLs, no vendored
binaries.

## Hard rules

- Every cask and formula MUST pin an exact upstream version + `sha256` and MUST
  point `url` at a real release asset. A formula may rely on the version
  unambiguously encoded in its immutable release URL; adding a duplicate
  explicit `version` stanza makes Homebrew audit fail. Never add `:no_check` or
  a `live`/rolling URL. If the release has no `.sha256` asset, download the
  artifact and compute the hash with `shasum -a 256`.
- Never vendor or embed an app's binaries here. Each cask and formula is a thin wrapper.
- Ad-hoc-signed / un-notarized releases are common and fine, but they MUST
  ship a `postflight` that clears quarantine and re-signs locally (`xattr -cr`
  then `codesign --force --deep --sign -`) — `scripts/add-cask.sh --re-sign`
  emits this. If an app needs signing magic you can't explain, don't add it.
- The reverse holds too: NEVER add the re-sign `postflight` to an app that
  ships a valid Developer ID signature + notarization. Re-signing strips the
  real signature and breaks library validation for bundled runtimes (this is
  how the official jetbrains-junie formula corrupted Junie: brew rewrote the
  bundled JRE dylibs and ad-hoc re-signed them, so the launcher refused to
  load them). `codesign --verify --deep --strict` on the installed app is
  the gate.
- Every new or revised cask MUST satisfy the [Zap contract](#zap-contract).
  Add `caveats` for permission gotchas, including Accessibility grants lost
  after updates; caveats never replace implemented cleanup.
- `brew audit --new` admission rules (repo notability, notarization) do not apply
  to a personal tap. Do not add `--new` checks. There is no lint CI job;
  `autobump.yml` validates its own changes via `brew style` and `brew audit`,
  and manual bumps are verified locally before committing.

## Zap contract

`--zap` is the user's explicit opt-in to removing local app data. A successful
zap must remove all known cleanup targets; warning about retained data is not
an implementation. Keep data removal in `zap`, so ordinary uninstall preserves it.

- Inspect the pinned upstream source or artifact for bundle identifiers,
  storage paths, downloaded resources, helpers, and credential service names.
  Cover current defaults and known legacy locations. Generator output is a draft;
  guessed bundle paths alone do not establish complete cleanup.
- Include profiles, settings, sessions, app-managed workspaces, history, logs,
  caches, preferences, HTTP storage and binary cookies, WebKit data, saved state,
  updater downloads, models, and app-owned credentials wherever they exist.
- Include known shared resources that the app uses or downloads. Scope model
  cleanup to the identified repositories and their lock directories, or the
  identified SDK model directories. Do not omit them just because they are
  shared, or delete an entire common cache containing unrelated resources.
- Quit the app using its verified bundle identifier, with a `TERM` fallback.
  Unload app-owned launch agents/services before removing their files. Include
  installed helpers and remove CLI links only when their targets belong to the
  app; preserve foreign links and unrelated commands.
- Prefer `zap trash:` for paths. Use scripts only when ownership checks or
  credential cleanup require them. Delete all matching app-owned local Keychain
  entries using service names verified upstream. Only an absent item is a
  successful no-op; propagate other errors instead of swallowing them.
- Preserve unrelated documents, projects, and resources. Custom data locations
  and remote/iCloud credentials require verified ownership and an explicit
  cleanup rule. Document macOS permission or entitlement limits honestly;
  denied access is not evidence that data is absent or cleanup succeeded.
- Update [the zap audit](docs/cask-zap-audit.md) with source evidence and cleanup
  scope. Extend [the fixture suite](scripts/test-cask-zap.rb) for every added
  cask and changed storage or script behavior. Prove that app data disappears,
  unrelated data survives, ordinary uninstall preserves data, and cleanup
  errors propagate. Verification must use temporary fixtures and fake credentials.

## Workflow

Use `.agents/commands/add-package.md` for package intake. It dispatches to
`.agents/agents/homebrew-package-maintainer.md`, which loads
`.agents/skills/homebrew-package-maintenance/SKILL.md` for the detailed
workflow. Do not commit or push without explicit authorization.

The existing `scripts/add-cask.sh` remains the generator for GitHub-release
casks. Run `./scripts/add-cask.sh --help` for its options.

### Automation

`.github/workflows/autobump.yml` runs daily at 06:17 UTC and on
`workflow_dispatch`:

- Configure the `HOMEBREW_GITHUB_API_TOKEN` repository secret with a
  repository-scoped GitHub token. The Actions `GITHUB_TOKEN` can push branches
  but does not provide the token scope required by Homebrew's `--open-pr` helper.

- `autobump` — `brew bump --no-fork --open-pr` for every supported
  `livecheck`-enabled cask/formula (`agent-orchestrator`, `clearly`,
  `deepseek-harness`, `junie`, `kero`, `localvoxtral`, `mac-dictate-anywhere`,
  `mowglii-mdv`, `podium`, `prime-agent`, `qm`, `superset`, `tqbf-mdv`,
  `tuicommander`, `waku`, `writer-computer`, `zeron`). `qwen-code` and `maki`
  are excluded because Homebrew's generic bump parser cannot rewrite their
  architecture-specific URL stanzas; `bump-arch-formulae` uses the dedicated
  updater instead. Do not use `no_autobump!` in this personal tap because
  Homebrew rejects that DSL outside official taps. One PR per outdated package,
  de-duplicated against open PRs.
- `bump-optcgsim` — runs `scripts/update-optcgsim.sh` for the Dropbox-hosted
  cask that has no `livecheck`.
- `bump-junie-local` — runs `scripts/update-junie-local.sh` for the
  commit-pinned `junie-local` formula that has `livecheck skip`; version
  authority is the latest commit touching `local/install.sh`.
- `bump-arch-formulae` — runs `scripts/update-arch-formula.sh` for `qwen-code`
  and `maki`, which each have architecture-specific release assets.

No separate lint CI exists. Autobump validates its own edits; for hand-made
bumps run `brew style` + `brew audit` locally as in Verification before
committing.

## Conventions

- `brew style --fix` is the arbiter of stanza order — run it, don't fight it.
  Casks generally use `version, sha256, url`; formulas generally use
  `url, sha256, license`, with an explicit `version` only when Homebrew cannot
  infer it from the pinned URL.
- `desc` must start with a capital letter (a style cop).
- Default `depends_on macos: :sequoia` and `depends_on arch: :arm64` only when
  the app actually requires them; don't guess.
- If upstream ships separate arm64/amd64 macOS assets, use the `arch` stanza
  with per-arch `sha256` keys instead of pinning `depends_on arch: :arm64`.
- Keep the README's cask and formula tables in sync when adding a cask or formula.

## Verification

For cask additions or changes, run `brew ruby scripts/test-cask-zap.rb`; require
exit status 0 and the `PASS` result covering every cask. Run `brew style` on
the edited Ruby files. Use the applicable tap-qualified audit:
`brew audit --cask achembarpu/tap/<name>` or
`brew audit --formula achembarpu/tap/<name>`. Ensure the audit reads the edited
package, not a stale tapped copy. Run
`git diff --check` before committing. Do not use `--new`, exercise zap against
real user data as a test, or claim unavailable checks passed.

## Scope

- Casks wrap GUI apps from GitHub releases with `.zip` (preferred) or `.dmg` assets that contain a `.app` bundle. The documented non-GitHub exceptions are `kero`, which uses the upstream project's pinned R2 DMG and Sparkle appcast, and `mowglii-mdv`, which uses Mowglii's pinned S3 DMG and Sparkle appcast.
- Formulas wrap CLI tools and scripts that do not contain a `.app` bundle. Each formula pins an upstream artifact with an exact version and `sha256` (explicitly or through an immutable versioned release URL), no live fetches, no vendored binaries unless the build is from source. Use a GitHub release asset where available; the documented exceptions are `junie-local` (a pinned raw upstream script), `optcgsim` (a site-hosted app archive), and `prime-agent` and `qm` (npm tarballs whose declared dependencies are resolved during the build). See `junie-local` for a script wrapper and `prime-agent` for an npm tarball pattern.
- Uninstall runs `brew uninstall --cask --zap <name>` for casks (data paths come from the cask's `zap`) and `brew uninstall <name>` for formulae.
