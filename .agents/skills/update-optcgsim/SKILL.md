---
name: update-optcgsim
description: >
  Use when asked to update the optcgsim cask or check for a new version.
---

# Updating the optcgsim cask

The Mac build ships through links on https://optcgsim.com/. The Dropbox filename
is vestigial and the RSS feed may lag the actual download. The updater reads
bounded byte ranges to verify the embedded binary version and matching bundle
folder. It checks that the version is not older than the feed or cask, and
downloads and hashes the full archive only for a newer build.

1. Run `./scripts/update-optcgsim.sh`. It checks the archive even when the
   feed is unchanged, updates the cask if necessary, and runs style and audit.
2. Confirm the summary and run the cask verification required by `AGENTS.md`.
   Inspect the pinned artifact for any changes to its data and helper paths.
3. Update the zap audit when the artifact changes. Commit and push only with
   explicit authorization.

`--dry-run` inspects archive byte ranges without writing the cask;
`--version` requires an exact binary version. Both Dropbox and the Google Drive
mirror may be temporarily unavailable or reject byte ranges; the updater exits
75 without downloading the full archive in that case.
