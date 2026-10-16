# typed: strict
# frozen_string_literal: true

# Run with: brew ruby scripts/test-cask-zap.rb
require "cask/cask_loader"
require "cask/artifact/zap"
require "cask/artifact/uninstall"
require "fileutils"
require "open3"
require "tmpdir"

tap_root = File.expand_path("..", __dir__)
casks = Dir["#{tap_root}/Casks/*.rb"].map { |path| Cask::CaskLoader::FromContentLoader.new(File.read(path)).load(config: nil) }

check = ->(condition, message) { raise message unless condition }

fluid_audio_models = %w[
  parakeet-tdt-0.6b-v2 parakeet-tdt-0.6b-v3 parakeet-ultra
  parakeet-tdt-ctc-110m parakeet-ctc-110m-coreml sensevoice-small
  parakeet-eou-streaming/320ms nemotron-streaming/560ms
  nemotron-streaming/1120ms nemotron-streaming/2240ms
  nemotron-multilingual/multilingual/1120ms
]
fluid_audio_fixtures = fluid_audio_models.map do |name|
  "~/Library/Application Support/FluidAudio/Models/#{name}/weights"
end

# These fixtures reproduce the storage locations that motivated the audit.
storage = {
  "agent-orchestrator"   => ["~/.ao/electron/settings.json"],
  "clearly"              => ["~/Library/Application Support/Clearly/diagnostic.log",
                             "~/Library/Application Support/Scratchpads/note.md"],
  "happier"              => ["~/.happier/servers/cloud/access.key",
                             "~/.happier/servers/cloud/memory/models/weights",
                             "~/.happier/sessions/session.json",
                             "~/.happier/cli/versions/0.2.16/happier",
                             "~/.happier/self-host/data/relay.db",
                             "~/Library/Application Support/dev.happier.app/tray-state.json",
                             "~/Library/LaunchAgents/Happier.plist",
                             "~/Library/LaunchAgents/com.happier.cli.daemon.plist",
                             "~/Library/LaunchAgents/com.happier.cli.daemon.default.plist",
                             "~/Library/LaunchAgents/com.happier.cli.daemon.cloud.plist",
                             "~/Library/LaunchAgents/happier-server.plist"],
  "intent"               => ["~/Library/Application Support/intent-cloudlands/settings.json",
                             "~/Library/Application Support/intentd/workspaces.db",
                             "~/Library/Caches/intent-updater/update.zip"],
  "junie"                => ["~/.junie/settings.json", "~/.local/share/junie/logs/session.log"],
  "kero"                 => ["~/.config/kero/config.toml", "~/Library/Application Support/kero/sessions.db"],
  "localvoxtral"         => ["~/Library/Application Support/localvoxtral/history.json",
                             "~/Library/LaunchAgents/com.localvoxtral.login.plist",
                             "~/.claude/plugins/cache/localvoxtral/localvoxtral/1/hook.sh",
                             "~/.claude/plugins/marketplaces/localvoxtral/marketplace.json",
                             "~/.claude/skills/localvoxtral-doctor/SKILL.md",
                             "~/.codex/.tmp/marketplaces/localvoxtral/marketplace.json",
                             "~/.codex/plugins/cache/localvoxtral/localvoxtral/1/hook.sh",
                             "~/.codex/plugins/data/localvoxtral-localvoxtral/settings.json",
                             "~/.codex/skills/localvoxtral-doctor/SKILL.md",
                             "~/.config/opencode/plugins/localvoxtral.js",
                             "~/.config/opencode/skills/localvoxtral-doctor/SKILL.md",
                             "~/.vibe/localvoxtral/publish.sh",
                             "~/.vibe/skills/localvoxtral-doctor/SKILL.md",
                             "~/.local/share/localvoxtral/claude-marketplace/marketplace.json",
                             "~/.cache/huggingface/hub/models--mlx-community--Qwen3.5-4B-OptiQ-4bit/weights",
                             "~/.cache/huggingface/hub/.locks/models--mlx-community--Qwen3.5-4B-OptiQ-4bit/lock"],
  "mac-dictate-anywhere" => ["~/Library/Application Support/Dictate Anywhere/Cancelled Dictations/audio.wav"] +
                            fluid_audio_fixtures,
  "mowglii-mdv"          => ["~/Library/Preferences/com.mowglii.MDV.plist"],
  "optcgsim"             => ["~/Library/Application Support/Batsu/OPTCGSim/decks.json",
                             "~/Library/Application Support/com.Batsu.OPTCGSim/deck.txt",
                             "~/Library/Application Support/Godot/app_userdata/OPBounty/uinf.tres",
                             "~/Library/Application Support/Godot/app_userdata/OPBounty/Decks/deck.txt",
                             "~/Library/Application Support/Godot/app_userdata/OPBounty/my_matches",
                             "~/Library/Application Support/Godot/app_userdata/OPBounty/imgs/card.jpg",
                             "~/Library/Application Support/Godot/app_userdata/OPBounty/logs/godot.log",
                             "~/Library/Application Support/Godot/app_userdata/OPBounty/OPBounty.pck"],
  "podium"               => ["~/.podium/config.json", "~/.podium/logs/desktop-native.ndjson"],
  "superset"             => ["~/.superset/sessions/session.json",
                             "~/Library/Application Support/Superset/Preferences",
                             "~/Library/Caches/@supersetdesktop-updater/update.zip"],
  "tqbf-mdv"             => ["~/Library/Application Support/mdv/mdv.db"],
  "tuicommander"         => ["~/.tuicommander/config.json",
                             "~/Library/Application Support/tuicommander/config.json",
                             "~/Library/Application Support/tui-commander/config.json",
                             "~/Library/Application Support/com.tuic.commander/config.json"],
  "waku"                 => ["~/.waku/settings.json", "~/Library/Application Support/Waku/sessions.db"],
  "writer-computer"      => ["~/Library/Application Support/com.writer-computer/preferences.json"],
  "zeron"                => ["~/.zeron/sessions/session.json"],
}
check.call(casks.map(&:token).sort == storage.keys.sort, "Add storage fixtures for every cask")

Dir.mktmpdir("cask-zap-test-") do |temporary|
  fixture_home = "#{temporary}/home"
  FileUtils.mkdir_p(fixture_home)
  real_home = Dir.method(:home)
  Dir.define_singleton_method(:home) { |*_args| fixture_home }
  begin
    casks.each do |cask|
      zap = cask.artifacts.grep(Cask::Artifact::Zap).fetch(0)
      uninstall = cask.artifacts.grep(Cask::Artifact::Uninstall).fetch(0)
      check.call(!uninstall.directives.key?(:trash) && !uninstall.directives.key?(:delete) &&
            !uninstall.directives.key?(:script) && !uninstall.directives.key?(:early_script),
                 "#{cask.token}: data cleanup must require --zap")
      bundles = Array(uninstall.directives.fetch(:quit))
      check.call(uninstall.directives.fetch(:signal) == bundles.map { |bundle| ["TERM", bundle] },
                 "#{cask.token}: shutdown fallback missing")
      if cask.token == "optcgsim"
        check.call(bundles == ["com.Batsu.OPTCGSim", "com.smallindiedev.opbounty"],
                   "optcgsim: bundled OPBounty helper shutdown missing")
      end
      targets = zap.directives.fetch(:trash)
      check.call(targets.uniq == targets, "#{cask.token}: duplicate cleanup paths")

      fixture_paths = storage.fetch(cask.token) + bundles.flat_map do |bundle|
        ["~/Library/Caches/#{bundle}/cache.bin",
         "~/Library/HTTPStorages/#{bundle}.binarycookies",
         "~/Library/WebKit/#{bundle}/website.db"]
      end
      if %w[agent-orchestrator intent superset].include?(cask.token)
        fixture_paths << "~/Library/Preferences/ByHost/#{bundles.first}.ShipIt.fixture-host.plist"
      end
      fixtures = fixture_paths.map { |path| path.sub(/^~/, fixture_home) }
      sentinels = ["#{fixture_home}/Documents/keep.md",
                   "#{fixture_home}/Library/Caches/#{bundles.first}.other/keep.bin",
                   "#{fixture_home}/Library/Preferences/ByHost/#{bundles.first}.other.ShipIt.fixture.plist",
                   "#{fixture_home}/Library/Application Support/Godot/app_userdata/OtherGame/save.json",
                   "#{fixture_home}/Library/Application Support/FluidAudio/Models/unrelated-model/weights",
                   "#{fixture_home}/Library/Application Support/FluidAudio/Models/nemotron-multilingual/other/data",
                   "#{fixture_home}/Library/Application Support/FluidAudio/datasets/unrelated/file",
                   "#{fixture_home}/.claude/plugins/cache/other-marketplace/plugin/keep",
                   "#{fixture_home}/.codex/plugins/cache/other-marketplace/plugin/keep",
                   "#{fixture_home}/.config/opencode/plugins/other.js",
                   "#{fixture_home}/.claude/skills/other/SKILL.md",
                   "#{fixture_home}/.cache/huggingface/hub/models--unrelated--model/weights"]
      (fixtures + sentinels).each do |path|
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, "fixture")
      end

      # Exercise Homebrew's path resolver, then move only the resolved fixture
      # paths. No app, launchctl, Keychain, or real Trash command is executed.
      local_targets = targets.map { |path| path.sub(%r{^/usr/local/bin/}, "#{temporary}/bin/") }
      resolved = zap.each_resolved_path(:trash, local_targets).flat_map { |_pattern, paths| paths }
      check.call(resolved.all? do |path|
        path.to_s.start_with?("#{temporary}/")
      end, "Refusing cleanup outside the fixture")
      trash = "#{temporary}/trash/#{cask.token}"
      FileUtils.mkdir_p(trash)
      resolved.each_with_index { |path, index| FileUtils.mv(path, "#{trash}/#{index}") }
      check.call(fixtures.none? { |path| File.exist?(path) }, "#{cask.token}: app data survived zap")
      check.call(sentinels.all? { |path| File.exist?(path) }, "#{cask.token}: unrelated data was removed")
    end
  ensure
    Dir.define_singleton_method(:home, real_home)
  end

  # Fake the security executable to test multiple entries, missing entries,
  # and errors without touching the user's Keychain.
  security = "#{temporary}/security"
  File.write(security, <<~SH)
    #!/bin/sh
    printf '%s\\n' "$3" >> "$ZAP_TEST_LOG"
    if [ -n "$ZAP_TEST_ERROR" ]; then
      printf 'keychain denied\\n' >&2
      exit "$ZAP_TEST_ERROR"
    fi
    for entry in 1 2; do
      if mkdir "$ZAP_TEST_STATE/$3.$entry" 2>/dev/null; then exit 0; fi
    done
    exit 44
  SH
  File.chmod(0755, security)

  casks.each do |cask|
    directives = cask.artifacts.grep(Cask::Artifact::Zap).fetch(0).directives
    if cask.token == "tuicommander"
      require_relative "test-tuic-zap"
      TuicZapFixtures.verify(directives.fetch(:early_script), temporary, check)
    end
    if cask.token == "localvoxtral"
      require_relative "test-localvoxtral-zap"
      LocalvoxtralZapFixtures.verify(directives.fetch(:early_script), temporary, check)
    end
    script = directives[:script]
    next unless script

    if cask.token == "happier"
      require_relative "test-happier-zap"
      HappierZapFixtures.verify(script, temporary, check)
      next
    end
    if %w[agent-orchestrator intent junie superset].include?(cask.token)
      require_relative "test-app-process-zap"
      AppProcessZapFixtures.verify(cask.token, script, temporary, check)
      next
    end

    source = script.fetch(:args).fetch(1)
    if source.include?("/usr/bin/security")
      check.call(script[:sudo] == false, "#{cask.token}: Keychain cleanup must run as the user")
      source = source.sub("/usr/bin/security", security)
      state = "#{temporary}/security-#{cask.token}"
      FileUtils.mkdir_p(state)
      log = "#{state}/calls"
      environment = { "ZAP_TEST_LOG" => log, "ZAP_TEST_STATE" => state, "ZAP_TEST_ERROR" => "" }
      output, status = Open3.capture2e(environment, "/bin/sh", "-c", source)
      check.call(status.success?, "#{cask.token}: Keychain cleanup failed: #{output}")
      calls = File.readlines(log, chomp: true).tally
      check.call(calls.values.all?(3), "#{cask.token}: cleanup left a second Keychain entry")
      output, status = Open3.capture2e(environment, "/bin/sh", "-c", source)
      check.call(status.success?, "#{cask.token}: absent Keychain entries should succeed: #{output}")
      output, status = Open3.capture2e(environment.merge("ZAP_TEST_ERROR" => "50"), "/bin/sh", "-c", source)
      check.call(status.exitstatus == 50 && output.include?("keychain denied"),
                 "#{cask.token}: Keychain failure was swallowed")
    else
      link = "#{temporary}/#{cask.token}-cli"
      source = source.sub(/^link=.*$/, "link=\"#{link}\"")
      owned_target = source.match(%r{\*/([^/]+\.app/Contents/[^)]+)\)}).captures.fetch(0).sub("*", "bin/tool")
      ["#{temporary}/#{owned_target}", "#{temporary}/Other.app/Contents/bin/tool"].each do |target|
        File.symlink(target, link)
        output, status = Open3.capture2e("/bin/sh", "-c", source)
        check.call(status.success?, "#{cask.token}: CLI cleanup failed: #{output}")
        check.call(File.symlink?(link) == target.include?("Other.app"), "#{cask.token}: wrong CLI ownership behavior")
        File.unlink(link) if File.symlink?(link)
      end
      File.write(link, "unrelated command")
      output, status = Open3.capture2e("/bin/sh", "-c", source)
      check.call(status.success? && File.read(link) == "unrelated command",
                 "#{cask.token}: overwrote an unrelated CLI: #{output}")
      File.unlink(link)
      output, status = Open3.capture2e("/bin/sh", "-c", source)
      check.call(status.success?, "#{cask.token}: absent CLI link should succeed: #{output}")
      File.symlink("#{temporary}/#{owned_target}", link)
      failing_rm = "#{temporary}/failing-rm"
      File.write(failing_rm, "#!/bin/sh\nexit 55\n")
      File.chmod(0755, failing_rm)
      output, status = Open3.capture2e("/bin/sh", "-c", source.gsub("/bin/rm", failing_rm))
      check.call(status.exitstatus == 55 && File.symlink?(link), "#{cask.token}: CLI cleanup error was swallowed")
      File.unlink(link)
      bundle = owned_target.split("/Contents/").first
      File.symlink("#{temporary}/#{bundle}/Contents/../../Other.app/tool", link)
      output, status = Open3.capture2e("/bin/sh", "-c", source)
      check.call(status.success? && File.symlink?(link), "#{cask.token}: removed a link escaping the app: #{output}")
      File.unlink(link)
    end
  end
end

puts "PASS: #{casks.length} casks; data cleanup, opt-in behavior, CLI ownership, and Keychain errors"
