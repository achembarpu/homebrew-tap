# typed: strict
# frozen_string_literal: true

require "json"

# Verifies shared integration settings using temporary files only.
module LocalvoxtralZapFixtures
  def self.verify(script, temporary, check)
    home = "#{temporary}/localvoxtral-home"
    write = lambda do |relative, content|
      path = "#{home}/#{relative}"
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
      path
    end
    read_json = ->(relative) { JSON.parse(File.read("#{home}/#{relative}")) }
    plugin = "localvoxtral@localvoxtral"
    foreign_plugin = "other@elsewhere"
    original_command = "printf '%s' user-status"
    quote = ->(value) { "'#{value.gsub("'") { "'\\''" }}'" }
    wrapper = <<~SH
      #!/bin/sh
      # Written by localvoxtral: your status line, then its connection indicator.
      # Settings > Claude Code > Status line > Remove puts your command back.
      original_command=#{quote.call(original_command)}
      hook='/Applications/localvoxtral.app/Contents/MacOS/localvoxtral-claude-hook'
      input=$(cat)
      yours=$(printf '%s' "$input" | sh -c "$original_command")
      lvx=''
      if [ -x "$hook" ]; then
        lvx=$(printf '%s' "$input" | "$hook" --statusline)
      fi
      if [ -n "$yours" ] && [ -n "$lvx" ]; then
        printf '%s  %s\\n' "$yours" "$lvx"
      else
        printf '%s%s\\n' "$yours" "$lvx"
      fi
    SH
    wrapper_path = write.call(".claude/localvoxtral-statusline.sh", wrapper)
    settings = {
      "theme"          => "user-theme",
      "enabledPlugins" => { plugin => true, foreign_plugin => true },
      "statusLine"     => { "type" => "command", "command" => "~/.claude/localvoxtral-statusline.sh",
"padding" => 1 },
    }
    settings_path = write.call(".claude/settings.json", JSON.generate(settings))
    write.call(".claude/plugins/installed_plugins.json", JSON.generate({
      "version" => 2,
      "plugins" => { plugin         => [{ "scope" => "user" }, { "scope" => "project", "projectPath" => "/keep" }],
                     foreign_plugin => [{ "scope" => "user" }] },
    }))
    write.call(".claude/plugins/known_marketplaces.json", JSON.generate({ "localvoxtral" => {}, "other" => {} }))
    write.call(".config/opencode/tui.json", JSON.generate({ "plugin" => ["./plugins/localvoxtral.js", "other"],
                                                            "theme"  => "keep" }))
    write.call(".codex/config.toml", <<~TOML)
      model = "keep-model"
      [plugins."localvoxtral@localvoxtral"]
      enabled = true
      [plugins."localvoxtral@localvoxtral".user_config]
      option = "app-setting"
      [plugins."other@elsewhere"]
      enabled = false
      [marketplaces.localvoxtral]
      source_type = "local"
      source = "/app-owned"
      [marketplaces.other]
      source_type = "git"
      source = "https://example.invalid/keep.git"
    TOML
    blocks = {
      ".zshrc"            => ["# localvoxtral plain-ssh join (begin)", "# localvoxtral plain-ssh join (end)"],
      ".claude/CLAUDE.md" => ["<!-- begin localvoxtral dictation note -->",
                              "<!-- end localvoxtral dictation note -->"],
      ".vibe/hooks.toml"  => ["# >>> localvoxtral >>>", "# <<< localvoxtral <<<"],
      ".ssh/config"       => ["# BEGIN localvoxtral claude context (test-host)",
                              "# END localvoxtral claude context (test-host)"],
    }
    blocks.each do |relative, (first, last)|
      write.call(relative, "user-before\n#{first}\napp-owned\n#{last}\nuser-after\n")
    end
    File.chmod(0640, "#{home}/.zshrc")
    source = script.fetch(:args).fetch(1).sub("home = Dir.home", "home = #{home.inspect}")
    execute = -> { Open3.capture2e(script.fetch(:executable), "-e", source) }
    output, status = execute.call
    check.call(status.success?, "localvoxtral: integration cleanup failed: #{output}")
    restored = read_json.call(".claude/settings.json")
    check.call(restored["theme"] == "user-theme" && restored["enabledPlugins"] == { foreign_plugin => true } &&
               restored["statusLine"] == { "type" => "command", "command" => original_command, "padding" => 1 },
               "localvoxtral: user settings or previous status line were lost")
    check.call(!File.exist?(wrapper_path), "localvoxtral: owned status-line wrapper survived")
    plugins = read_json.call(".claude/plugins/installed_plugins.json").fetch("plugins")
    project_registration = [{ "scope" => "project", "projectPath" => "/keep" }]
    check.call(plugins[plugin] == project_registration && plugins.key?(foreign_plugin),
               "localvoxtral: unrelated/project plugin registration was removed")
    check.call(read_json.call(".claude/plugins/known_marketplaces.json") == { "other" => {} },
               "localvoxtral: wrong marketplace scope")
    check.call(read_json.call(".config/opencode/tui.json") == { "plugin" => ["other"], "theme" => "keep" },
               "localvoxtral: unrelated opencode configuration was lost")
    config = File.read("#{home}/.codex/config.toml")
    check.call(config.exclude?("localvoxtral") && config.include?('model = "keep-model"') &&
               config.include?("enabled = false") && config.include?("https://example.invalid/keep.git"),
               "localvoxtral: wrong Codex configuration cleanup scope")
    blocks.each_key do |relative|
      check.call(File.read("#{home}/#{relative}") == "user-before\nuser-after\n", "localvoxtral: wrong marker scope")
    end
    check.call(File.stat("#{home}/.zshrc").mode & 0777 == 0640, "localvoxtral: changed shell-profile permissions")
    output, status = execute.call
    check.call(status.success?, "localvoxtral: absent integrations should succeed: #{output}")

    # Direct app status lines are removed; foreign commands remain byte-for-byte.
    hook_command = "/Applications/localvoxtral.app/Contents/MacOS/localvoxtral-claude-hook --statusline"
    direct_status = { "type" => "command", "command" => hook_command }
    File.write(settings_path, JSON.generate({ "statusLine" => direct_status, "keep" => true }))
    output, status = execute.call
    check.call(status.success? && read_json.call(".claude/settings.json") == { "keep" => true },
               "localvoxtral: direct status line survived: #{output}")
    foreign_settings = JSON.generate({ "statusLine" => { "type" => "command", "command" => "printf 'user-status" } })
    File.write(settings_path, foreign_settings)
    output, status = execute.call
    check.call(status.success? && File.read(settings_path) == foreign_settings,
               "localvoxtral: foreign status line was changed: #{output}")
    config_path = "#{home}/.codex/config.toml"
    preserved_config = File.read(config_path)
    ["[plugins]\n\"localvoxtral@localvoxtral\" = { enabled = true }\n",
     "[marketplaces]\nlocalvoxtral = { source_type = \"local\" }\n",
     "[plugins.\"localvoxtral@localvoxtral\"]\nnote = \"\"\"multiline\"\"\"\n"].each do |ambiguous|
      File.write(config_path, ambiguous)
      output, status = execute.call
      check.call(!status.success? && File.read(config_path) == ambiguous,
                 "localvoxtral: ambiguous TOML was changed: #{output}")
    end
    File.write(config_path, preserved_config)

    # Failed preflight must leave shared user files untouched.
    original_profile = <<~PROFILE
      before
      # localvoxtral plain-ssh join (begin)
      app
      # localvoxtral plain-ssh join (end)
      after
    PROFILE
    write.call(".zshrc", original_profile)
    File.write(settings_path, "invalid JSON")
    output, status = execute.call
    check.call(!status.success? && File.read("#{home}/.zshrc") == original_profile,
               "localvoxtral: malformed shared settings were swallowed: #{output}")
    File.write(settings_path, JSON.generate(settings))
    File.write(wrapper_path, "#{wrapper}# user edit\n")
    output, status = execute.call
    check.call(!status.success? && File.exist?(wrapper_path), "localvoxtral: edited wrapper was discarded: #{output}")
    File.write(wrapper_path, wrapper)
    write.call(".zshrc", "# localvoxtral plain-ssh join (begin)\nunclosed\n")
    output, status = execute.call
    check.call(!status.success?, "localvoxtral: unmatched marker was swallowed: #{output}")
    write.call(".zshrc", "user profile\n")
    foreign = write.call("Documents/foreign.json", '{"keep":true}')
    File.unlink("#{home}/.config/opencode/tui.json")
    File.symlink(foreign, "#{home}/.config/opencode/tui.json")
    output, status = execute.call
    check.call(status.success? && File.symlink?("#{home}/.config/opencode/tui.json") &&
               File.read(foreign) == '{"keep":true}', "localvoxtral: foreign symlink target was changed: #{output}")
    File.write(foreign, JSON.generate({ "plugin" => ["./plugins/localvoxtral.js", "keep"], "theme" => "keep" }))
    output, status = execute.call
    check.call(status.success? && File.symlink?("#{home}/.config/opencode/tui.json") &&
               JSON.parse(File.read(foreign)) == { "plugin" => ["keep"], "theme" => "keep" },
               "localvoxtral: wrong ownership scope through shared-config symlink: #{output}")
  end
end
