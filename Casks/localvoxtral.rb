cask "localvoxtral" do
  version "0.15.0"
  sha256 "e9bd7c86aa20121fe68c921b6082bf5e1ad1bbdfdf7e6f96f4451c66270d4c65"

  url "https://github.com/T0mSIlver/localvoxtral/releases/download/v#{version}/localvoxtral-v#{version}.zip"
  name "localvoxtral"
  desc "Realtime, fully local dictation for the menu bar"
  homepage "https://github.com/T0mSIlver/localvoxtral"

  livecheck do
    url "https://github.com/T0mSIlver/localvoxtral/releases/latest"
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "localvoxtral.app"

  # Releases are ad-hoc signed, not notarized. The official installer clears
  # quarantine and re-signs locally before the bundle enters /Applications;
  # replicate that here so first launch works on macOS 15 and macOS 26 alike
  # (macOS 26 can hang on a foreign ad-hoc signature during Gatekeeper's
  # first-exec scan unless the bundle is re-signed locally).
  postflight_steps do
    run "/usr/bin/xattr", args: ["-cr", "{{appdir}}/localvoxtral.app"]
    run "/usr/bin/codesign",
        args: ["--force", "--deep", "--sign", "-", "{{appdir}}/localvoxtral.app"]
  end

  uninstall launchctl: "com.localvoxtral.login",
            quit:      "com.localvoxtral.app",
            signal:    ["TERM", "com.localvoxtral.app"]

  zap early_script: {
        executable: "/usr/bin/ruby",
        args:       ["-e", <<~'RUBY'],
          require "json"
          require "shellwords"
          require "tempfile"
          home = Dir.home
          changes = []
          deletions = []
          resolved = {}
          read_owned = lambda do |relative|
            begin
              path = File.realpath(File.join(home, relative))
              resolved[relative] = path
              File.read(path)
            rescue Errno::ENOENT
              nil
            end
          end
          edit = lambda do |relative, &transform|
            content = read_owned.call(relative)
            if content
              updated = transform.call(content)
              changes << [resolved.fetch(relative), content, updated] unless updated == content
            end
          end
          markers = {
            "# localvoxtral plain-ssh join (begin)" => "# localvoxtral plain-ssh join (end)",
            "<!-- begin localvoxtral dictation note -->" => "<!-- end localvoxtral dictation note -->",
            "# >>> localvoxtral >>>" => "# <<< localvoxtral <<<",
            "# >>> localvoxtral remote >>>" => "# <<< localvoxtral remote <<<",
          }
          remove_blocks = lambda do |content|
            ending = nil
            kept = content.each_line.reject do |line|
              text = line.strip
              beginning = markers[text]
              beginning ||= text.sub("# BEGIN", "# END") if /\A# BEGIN localvoxtral claude context \([^)]+\)\z/.match?(text)
              if ending
                abort "Nested localvoxtral markers; refusing to change user settings" if beginning
                ending = nil if text == ending
                true
              elsif beginning
                ending = beginning
                true
              else
                abort "Unpaired localvoxtral marker" if markers.value?(text) || text.start_with?("# END localvoxtral claude context (")
                false
              end
            end
            abort "Unpaired localvoxtral marker" if ending
            kept.join
          end
          %w[.zshrc .bashrc .bash_profile .config/fish/conf.d/localvoxtral.fish
             .claude/CLAUDE.md .config/opencode/AGENTS.md .vibe/AGENTS.md
             .codex/AGENTS.md .codex/AGENTS.override.md .vibe/hooks.toml .ssh/config].each do |relative|
            edit.call(relative, &remove_blocks)
          end

          # Combine stores the user's previous status line. Restore it before deleting
          # our wrapper, and refuse an edited wrapper rather than lose that command.
          wrapper_path = ".claude/localvoxtral-statusline.sh"
          wrapper = read_owned.call(wrapper_path)
          original = nil
          if wrapper && wrapper.start_with?("#!/bin/sh\n# Written by localvoxtral: your status line, then its connection indicator.\n")
            original_text = wrapper[/\noriginal_command=(.*?)\nhook=/m, 1]
            hook_text = wrapper[/\nhook=(.*?)\ninput=\$\(cat\)/m, 1]
            if original_text && hook_text
              originals = Shellwords.split(original_text)
              hooks = Shellwords.split(hook_text)
              body = <<~'SH'
                input=$(cat)
                yours=$(printf '%s' "$input" | sh -c "$original_command")
                lvx=''
                if [ -x "$hook" ]; then
                  lvx=$(printf '%s' "$input" | "$hook" --statusline)
                fi
                if [ -n "$yours" ] && [ -n "$lvx" ]; then
                  printf '%s  %s\n' "$yours" "$lvx"
                else
                  printf '%s%s\n' "$yours" "$lvx"
                fi
              SH
              header = "#!/bin/sh\n# Written by localvoxtral: your status line, then its connection indicator.\n" \
                       "# Settings > Claude Code > Status line > Remove puts your command back.\n"
              expected = header + "original_command=" + original_text + "\nhook=" + hook_text + "\n" + body
              if wrapper == expected && originals.length == 1 && hooks.length == 1
                original = originals.first
                deletions << File.join(home, wrapper_path)
              end
            end
          end
          plugin_ids = %w[localvoxtral@localvoxtral localvoxtral-mod@localvoxtral localvoxtral-remote@localvoxtral]
          edit.call(".claude/settings.json") do |content|
            data = JSON.parse(content)
            before = Marshal.dump(data)
            %w[enabledPlugins].each do |key|
              next unless data[key].is_a?(Hash)
              plugin_ids.each { |id| data[key].delete(id) }
            end
            data["extraKnownMarketplaces"].delete("localvoxtral") if data["extraKnownMarketplaces"].is_a?(Hash)
            status = data["statusLine"]
            if status.is_a?(Hash) && status["type"] == "command" && status["command"].is_a?(String)
              command = status["command"]
              if ["~/" + wrapper_path, File.join(home, wrapper_path)].include?(command)
                abort "Cannot restore the original status line from the edited or absent wrapper" unless original
                data["statusLine"] = status.merge("command" => original)
              elsif command.include?("localvoxtral-claude-hook")
                words = Shellwords.split(command)
                if words.length == 2 && File.basename(words.first) == "localvoxtral-claude-hook" && words.last == "--statusline"
                  data.delete("statusLine")
                end
              end
            end
            Marshal.dump(data) == before ? content : JSON.pretty_generate(data) + "\n"
          end
          %w[.claude/plugins/installed_plugins.json .claude/plugins/known_marketplaces.json].each do |relative|
            edit.call(relative) do |content|
              data = JSON.parse(content)
              before = Marshal.dump(data)
              if relative.end_with?("installed_plugins.json")
                abort "Unknown Claude plugin registry schema" unless data["plugins"].is_a?(Hash)
                plugin_ids.each do |id|
                  entries = data["plugins"][id]
                  next unless entries
                  abort "Unknown Claude installed-plugin entry" unless entries.is_a?(Array)
                  entries.reject! { |entry| entry["scope"] == "user" }
                  data["plugins"].delete(id) if entries.empty?
                end
              else
                data.delete("localvoxtral")
              end
              Marshal.dump(data) == before ? content : JSON.pretty_generate(data) + "\n"
            end
          end
          edit.call(".config/opencode/tui.json") do |content|
            data = JSON.parse(content)
            before = Marshal.dump(data)
            if data.key?("plugin")
              abort "Unknown opencode plugin schema" unless data["plugin"].is_a?(Array)
              data["plugin"].delete("./plugins/localvoxtral.js")
            end
            Marshal.dump(data) == before ? content : JSON.pretty_generate(data) + "\n"
          end
          edit.call(".codex/config.toml") do |content|
            owned = /\A(?:plugins\.(?:"localvoxtral@localvoxtral"|'localvoxtral@localvoxtral')|marketplaces\.(?:localvoxtral|"localvoxtral"|'localvoxtral'))(?:\.|\z)/
            # CLI-generated tables are supported. Ambiguous multiline/inline forms
            # fail before any file is changed instead of guessing at TOML boundaries.
            has_owned_table = content.each_line.any? do |line|
              header = /\A\[\[?(.+?)\]\]?\s*(?:#.*)?\z/.match(line.strip)
              header && owned.match?(header[1])
            end
            if has_owned_table && (content.include?('"""') || content.include?("'''"))
              abort "Multiline TOML needs the Codex plugin remove command before zap"
            end
            skipping = false
            namespace = nil
            content.each_line.reject do |line|
              text = line.strip
              if (header = /\A\[\[?(.+?)\]\]?\s*(?:#.*)?\z/.match(text))
                namespace = header[1]
                skipping = owned.match?(namespace)
              elsif text.start_with?("[") && text.include?("localvoxtral")
                abort "Unrecognized localvoxtral TOML table"
              elsif /\A["']localvoxtral@localvoxtral["']\s*=/.match?(text) ||
                    (namespace == "marketplaces" && /\A(?:localvoxtral|"localvoxtral"|'localvoxtral')\s*=/.match?(text))
                abort "Inline TOML needs the Codex plugin remove command before zap"
              end
              skipping && !text.empty? && !text.start_with?("#")
            end.join
          end
          changes.each do |path, original_content, content|
            abort "Shared settings changed during cleanup: #{path}" unless File.read(path) == original_content
            mode = File.stat(path).mode & 0777
            Tempfile.create([".localvoxtral-zap-", ".tmp"], File.dirname(path)) do |file|
              file.write(content)
              file.chmod(mode)
              file.close
              File.rename(file.path, path)
            end
          end
          deletions.each do |path|
            abort "Status-line wrapper changed during cleanup" unless File.read(path) == wrapper
            File.unlink(path)
          end
        RUBY
        sudo:       false,
      },
      launchctl:    "com.localvoxtral.login",
      script:       {
        executable: "/bin/sh",
        args:       ["-c", <<~SH],
          for service in com.localvoxtral.api-keys com.localvoxtral.app.cmux-socket; do
            while :; do
              output=$(/usr/bin/security delete-generic-password -s "$service" 2>&1)
              status=$?
              case "$status" in
                0) ;;
                44) break ;; # The item is already absent.
                *) printf '%s\n' "$output" >&2; exit "$status" ;;
              esac
            done
          done
        SH
        sudo:       false,
      },
      trash:        [
        "~/.cache/huggingface/hub/.locks/models--mlx-community--nemotron-3.5-asr-streaming-0.6b-8bit",
        "~/.cache/huggingface/hub/.locks/models--mlx-community--Qwen3.5-0.8B-8bit",
        "~/.cache/huggingface/hub/.locks/models--mlx-community--Qwen3.5-4B-OptiQ-4bit",
        "~/.cache/huggingface/hub/.locks/models--mlx-community--Qwen3.5-9B-OptiQ-4bit",
        "~/.cache/huggingface/hub/.locks/models--T0mSIlver--Voxtral-Mini-4B-Realtime-2602-4bit-qhead",
        "~/.cache/huggingface/hub/models--mlx-community--nemotron-3.5-asr-streaming-0.6b-8bit",
        "~/.cache/huggingface/hub/models--mlx-community--Qwen3.5-0.8B-8bit",
        "~/.cache/huggingface/hub/models--mlx-community--Qwen3.5-4B-OptiQ-4bit",
        "~/.cache/huggingface/hub/models--mlx-community--Qwen3.5-9B-OptiQ-4bit",
        "~/.cache/huggingface/hub/models--T0mSIlver--Voxtral-Mini-4B-Realtime-2602-4bit-qhead",
        "~/.claude/plugins/cache/localvoxtral",
        "~/.claude/plugins/marketplaces/localvoxtral",
        "~/.claude/skills/localvoxtral-doctor",
        "~/.codex/.tmp/marketplaces/localvoxtral",
        "~/.codex/plugins/cache/localvoxtral",
        "~/.codex/plugins/data/localvoxtral-localvoxtral",
        "~/.codex/skills/localvoxtral-doctor",
        "~/.config/opencode/plugins/localvoxtral.js",
        "~/.config/opencode/skills/localvoxtral-doctor",
        "~/.local/share/localvoxtral",
        "~/.vibe/localvoxtral",
        "~/.vibe/skills/localvoxtral-doctor",
        "~/Library/Application Support/localvoxtral",
        "~/Library/Caches/com.localvoxtral.app",
        "~/Library/Containers/com.localvoxtral.app.widgets",
        "~/Library/HTTPStorages/com.localvoxtral.app",
        "~/Library/HTTPStorages/com.localvoxtral.app.binarycookies",
        "~/Library/LaunchAgents/com.localvoxtral.login.plist",
        "~/Library/Logs/com.localvoxtral.app",
        "~/Library/Preferences/com.localvoxtral.app.plist",
        "~/Library/Saved Application State/com.localvoxtral.app.savedState",
        "~/Library/WebKit/com.localvoxtral.app",
      ]

  caveats <<~EOS
    macOS may silently drop the Accessibility grant after the app bundle is
    replaced (updates). If the dictation hotkey stops working, toggle
    localvoxtral off and on in System Settings → Privacy & Security →
    Accessibility.

    Zap removes local integration entries and marked blocks from shared agent,
    shell, and SSH settings, preserving other settings. It restores the previous
    Claude status line from the unmodified app wrapper. Edited wrappers or
    ambiguous configuration cause an error and need manual resolution.

    First launch runs a setup wizard: microphone + Accessibility permissions
    and a one-time engine/model download from Hugging Face.
  EOS
end
