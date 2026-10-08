# Cask cleanup audit

Checked against the linked release versions on 2026-10-06. Every cask quits the app
before uninstalling and has an opt-in `zap` covering local app state. The lists
include the exact bundle identifier's macOS caches, HTTP storage and cookies,
logs, preferences, saved state, and WebKit storage when those paths exist.

`--zap` includes shared app resources. Intent's daemon data and Dictate
Anywhere's FluidAudio downloads are cleanup targets, rather than exclusions.
The filesystem targets use Homebrew's `trash:` directive. App-owned Keychain
entries are deleted; a missing entry is success, and other Keychain errors fail
the command. Optional CLI links are checked against their app bundle before
removal, so a different program using the same command name is unaffected.

| Cask | Additional cleanup checked | Evidence |
| --- | --- | --- |
| `agent-orchestrator` | `~/.ao`, the Electron profile, and app logs | [Pinned app storage setup](https://github.com/Untrivial-ai/agent-orchestrator/blob/v0.13.3/frontend/src/main.ts) and [bundle identifier](https://github.com/Untrivial-ai/agent-orchestrator/blob/v0.13.3/frontend/forge.config.ts) |
| `clearly` | `Application Support/Clearly`, scratchpads, and the app-owned `~/.local/bin/clearly` link from earlier releases | [Diagnostic log](https://github.com/Shpigford/clearly/blob/v3.3.0/Packages/ClearlyCore/Sources/ClearlyCore/Diagnostics/DiagnosticLog.swift), [scratchpads](https://github.com/Shpigford/clearly/blob/v3.3.0/Clearly/ScratchpadStore.swift), and [CLI history](https://github.com/Shpigford/clearly/blob/v3.3.0/CHANGELOG.md) |
| `intent` | `Application Support/intent-cloudlands`, `intentd`, the previous `Intent` profile, and `intent-updater` | Pinned [release archive](https://github.com/intent-hq/cloudlands-releases/releases/tag/v2.201.1): `app.asar/dist/main/index.js`, `dist/features/backend/main/intentd-data-dir.js`, and `app-update.yml` |
| `junie` | `~/.junie`, `~/.local/share/junie`, and the actual CLI app bundle identifier | Pinned [release archive](https://github.com/JetBrains/junie/releases/tag/3419.29): `Applications/junie.app/Contents/Info.plist` identifies `com.intellij.ml.llm.matterhorn.ej.app.cli.standalone` |
| `kero` | `~/.config/kero`, `Application Support/kero`, and `sh.kero` storage | Pinned [DMG](https://releases.kero.sh/kero-0.1.48.dmg): `Kero.app/Contents/Info.plist` and executable strings |
| `localvoxtral` | App data and widget container; unload and remove `com.localvoxtral.login`; remove the five catalog model repositories and their Hugging Face lock directories; remove API-key and cmux-password Keychain services | [Data directory](https://github.com/T0mSIlver/localvoxtral/blob/v0.11.0/Sources/localvoxtralCore/LocalvoxtralDataDirectory.swift), [login agent](https://github.com/T0mSIlver/localvoxtral/blob/v0.13.0/Sources/localvoxtral/LoginItem.swift), [speech catalog](https://github.com/T0mSIlver/localvoxtral/blob/v0.13.0/Sources/localvoxtralCore/SpeechModelCatalog.swift), [polish catalog](https://github.com/T0mSIlver/localvoxtral/blob/v0.13.0/Sources/localvoxtralCore/PolishModelCatalog.swift), and [Keychain store](https://github.com/T0mSIlver/localvoxtral/blob/v0.13.0/Sources/localvoxtral/KeychainSecretStore.swift) |
| `mac-dictate-anywhere` | `Application Support/Dictate Anywhere`, recovery recordings, S1-mini and shared FluidAudio models, and the three app-owned API-key Keychain services | Pinned [source](https://github.com/hoomanaskari/mac-dictate-anywhere/tree/v2.12.5/Dictate%20Anywhere): `DictationRecovery.swift`, `S1MiniModelManager.swift`, `TranscriptionEngine.swift`, and `Settings.swift` |
| `mowglii-mdv` | `com.mowglii.MDV` storage and the app-owned `~/.local/bin/mdv` link | Pinned [DMG](https://mowglii.s3.us-east-1.amazonaws.com/mdv/MDV-144-1.2.0.dmg): `MDV.app/Contents/Info.plist` and executable strings identifying `Contents/bin/mdv` |
| `optcgsim` | Current `Application Support/com.Batsu.OPTCGSim` and legacy `Batsu/OPTCGSim` data; bundled OPBounty's `Application Support/Godot/app_userdata/OPBounty` profile, saved credentials, decks, history, images, logs and downloaded updates; quit both app identifiers and clean their macOS storage | Rechecked the pinned 1.44a [Mac archive](../Casks/optcgsim.rb) on 2026-10-08: main and helper `Contents/Info.plist` identify `com.Batsu.OPTCGSim` and `com.smallindiedev.opbounty`. The helper's `Contents/Resources/OPBounty.pck` contains `Scenes/main.gd` (Mac deck path, `my_matches`), `Scripts/login.gd` (`uinf.tres` credentials), `Scripts/CardsDB.gd` (`imgs`), `Scripts/update_game.gd` (`OPBounty.pck` download), and `project.binary` (Godot project name `OPBounty`) |
| `podium` | `~/.podium`, including daemon configuration and logs, plus `app.podium.desktop` storage | [State-directory resolution](https://github.com/madeinorbit/podium/blob/v0.1.0/apps/desktop/src-tauri/src/bootstrap.rs) and [native logs](https://github.com/madeinorbit/podium/blob/v0.1.0/apps/desktop/src-tauri/src/logging.rs) |
| `superset` | `~/.superset`, the `Application Support/Superset` Electron profile, app logs, and updater cache | [State-directory name](https://github.com/superset-sh/superset/blob/desktop-v1.35.0/apps/desktop/src/shared/constants.ts), [production profile setup](https://github.com/superset-sh/superset/blob/desktop-v1.35.0/apps/desktop/src/main/index.ts), and pinned [release archive](https://github.com/superset-sh/superset/releases/tag/desktop-v1.35.0) `app-update.yml` (`@supersetdesktop-updater`) |
| `tqbf-mdv` | `Application Support/mdv`, including history and bookmarks | [Database location](https://github.com/tqbf/mdv/blob/v1.5.1/mdv/Database.swift) |
| `tuicommander` | Current and legacy config directories, `/usr/local/bin/tuic`, and current and legacy app-owned Keychain services | [Config migration paths](https://github.com/sstraus/tuicommander/blob/v1.7.6/src-tauri/src/config.rs), [CLI install path](https://github.com/sstraus/tuicommander/blob/v1.7.6/src-tauri/src/tuic_cli.rs), and [credential services](https://github.com/sstraus/tuicommander/blob/v1.7.6/src-tauri/src/credentials.rs) |
| `waku` | `~/.waku` and `Application Support/Waku` | [Settings location](https://github.com/egoist/waku/blob/v0.1.20/crates/waku-protocol/src/settings.rs) and [storage identity](https://github.com/egoist/waku/blob/v0.1.20/crates/waku-protocol/src/identity.rs) |
| `writer-computer` | `com.writer-computer` application data and the app-owned `/usr/local/bin/writer` link | [Settings location](https://github.com/joelbqz/writer-computer/blob/v0.7.2/apps/desktop/src-tauri/src/commands/settings.rs), [bundle identifier](https://github.com/joelbqz/writer-computer/blob/v0.7.2/apps/desktop/src-tauri/tauri.conf.json), and [CLI link](https://github.com/joelbqz/writer-computer/blob/v0.7.2/apps/desktop/src-tauri/src/commands/shell_install.rs) |
| `zeron` | `~/.zeron` and `sh.zeron.app` storage | [Engine data directory](https://github.com/zeronsh/zeron/blob/v0.2.102/crates/engine/src/lib.rs) and [bundle identifier](https://github.com/zeronsh/zeron/blob/v0.2.102/dist/macos/Info.plist) |

This audit covers default local storage and known legacy paths. User-selected
document locations, custom data directories and model repositories, external
agent installations, and remote or iCloud-synchronized data require their own
ownership and cleanup rules. macOS permissions still apply to Homebrew's trash
operation.

Run `brew ruby scripts/test-cask-zap.rb` to check cleanup against temporary
filesystem fixtures, including unrelated sibling data and CLI-name collisions.
The test replaces Keychain access with a fake executable and never uninstalls
an app or reads real credentials.
