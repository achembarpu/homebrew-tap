# typed: strict
# frozen_string_literal: true

require "digest"
require "etc"
require "json"

# Called by test-cask-zap.rb. All OS operations and credentials are fixtures.
module HappierZapFixtures
  def self.verify(script, temporary, check)
    check.call(script[:sudo] == false, "happier: cleanup must run as the user")
    fixture_home = "#{temporary}/happier-home"
    root = "#{fixture_home}/.happier"
    tools_dir = "#{temporary}/happier-tools"
    FileUtils.mkdir_p([root, tools_dir, "#{fixture_home}/.local/bin"])
    managed_home = "#{root}/servers/cloud/daemon/connected-services/homes/claude-subscription/profile/claude"
    FileUtils.mkdir_p(managed_home)
    File.write("#{managed_home}/.happier-claude-connected-service-home.json", '{"v":1}')
    service = "Claude Code-credentials-#{Digest::SHA256.hexdigest(managed_home)[0, 8]}"
    user = Etc.getpwuid.name
    state_path = "#{tools_dir}/state.json"
    log_path = "#{tools_dir}/calls.jsonl"
    initial_state = {
      "credentials" => [[service, user], [service, user], [service, "other-user"],
                        ["Claude Code-credentials", user], ["Claude Code-credentials-deadbeef", user]],
      "services"    => ["Happier", "com.happier.cli.daemon", "com.happier.cli.daemon.default",
                        "com.happier.cli.daemon.cloud", "happier-server", "com.other.daemon"],
      "running"     => [1234, 4567, 6789],
    }
    File.write(state_path, JSON.generate(initial_state))

    fake = <<~RUBY
      #!/usr/bin/ruby
      require "json"
      name = File.basename($PROGRAM_NAME)
      File.open(ENV.fetch("ZAP_TEST_LOG"), "a") { |file| file.puts(JSON.generate([name, *ARGV])) }
      exit 50 if ENV["ZAP_TEST_FAIL"] == [name, ARGV.first].join(":")
      state_path = ENV.fetch("ZAP_TEST_STATE")
      state = JSON.parse(File.read(state_path))
      case name
      when "launchctl"
        if ARGV.first == "list"
          state.fetch("services").each { |label| puts "- 0 " + label }
        else
          state.fetch("services").delete(ARGV.fetch(1))
        end
      when "ps"
        if ARGV.last == "pid=,comm="
          puts '1234 #{root}/cli/current/happier'
          puts '4567 #{root}/self-host/bin/happier-server'
          puts '6789 /opt/homebrew/bin/node'
          puts '7890 /usr/bin/less'
          puts '8901 /opt/homebrew/bin/node'
        else
          puts '1234 #{root}/cli/current/happier daemon start-sync' if state.fetch("running").include?(1234)
          puts '4567 #{root}/self-host/bin/happier-server serve' if state.fetch("running").include?(4567)
          puts '6789 /opt/homebrew/bin/node #{root}/cli/current/package-dist/index.mjs daemon start-sync' if state.fetch("running").include?(6789)
          puts '2345 #{fixture_home}/.happier-other/happier daemon start-sync'
          puts '3456 /usr/local/bin/happier daemon start-sync'
          puts '7890 /usr/bin/less #{root}/logs/daemon start-sync'
          puts '8901 /opt/homebrew/bin/node /other/script.js #{root}/cli/current/package-dist/index.mjs daemon start-sync'
        end
      when "security"
        service = ARGV.fetch(ARGV.index("-s") + 1)
        account = ARGV.fetch(ARGV.index("-a") + 1)
        index = state.fetch("credentials").index([service, account])
        exit 44 unless index
        state.fetch("credentials").delete_at(index)
      end
      File.write(state_path, JSON.generate(state))
    RUBY
    %w[launchctl ps security].each do |name|
      path = "#{tools_dir}/#{name}"
      File.write(path, fake)
      File.chmod(0755, path)
    end
    source = script.fetch(:args).fetch(1).sub("home = Dir.home", "home = #{fixture_home.inspect}")
    source = source.gsub("/bin/launchctl", "#{tools_dir}/launchctl")
                   .gsub("/bin/ps", "#{tools_dir}/ps")
                   .gsub("/usr/bin/security", "#{tools_dir}/security")
    source.prepend(<<~RUBY)
      require "json"
      Process.define_singleton_method(:kill) do |signal, pid|
        raise "Refusing non-fixture PID" unless [1234, 4567, 6789].include?(pid)
        state_path = ENV.fetch("ZAP_TEST_STATE")
        state = JSON.parse(File.read(state_path))
        raise Errno::ESRCH unless state.fetch("running").include?(pid)
        raise Errno::EPERM if ENV["ZAP_TEST_FAIL"] == "kill"
        next 1 if ENV["ZAP_TEST_FAIL"] == "stubborn"
        raise "Unexpected signal" unless signal == "TERM"
        state.fetch("running").delete(pid)
        File.write(state_path, JSON.generate(state))
      end
      def sleep(_duration); end
    RUBY
    environment = { "ZAP_TEST_LOG" => log_path, "ZAP_TEST_STATE" => state_path, "ZAP_TEST_FAIL" => "" }
    execute = ->(env = environment) { Open3.capture2e(env, script.fetch(:executable), "-e", source) }

    owned_link = "#{fixture_home}/.local/bin/happier"
    foreign_link = "#{fixture_home}/.local/bin/hprev"
    regular_command = "#{fixture_home}/.local/bin/hdev"
    File.symlink("../../.happier/bin/happier", owned_link)
    File.symlink("/opt/other/hprev", foreign_link)
    File.write(regular_command, "foreign command")
    profile = "#{fixture_home}/.zshrc"
    retained = "# User settings\nexport EDITOR=vi\n" \
               "# Added by Happier Desktop\nexport PATH=\"/custom/bin:$PATH\"\n"
    File.write(profile, retained + "# Added by Happier Desktop\nexport PATH=\"#{root}/bin:$PATH\"\n")

    output, status = execute.call
    check.call(status.success?, "happier: cleanup failed: #{output}")
    state = JSON.parse(File.read(state_path))
    check.call(state.fetch("services") == ["com.other.daemon"] && state.fetch("running").empty?,
               "happier: app services or managed daemon survived")
    check.call(state.fetch("credentials") == initial_state.fetch("credentials").drop(2),
               "happier: app credentials survived or unrelated credentials disappeared")
    check.call(!File.symlink?(owned_link) && File.symlink?(foreign_link) &&
               File.read(regular_command) == "foreign command", "happier: wrong CLI ownership behavior")
    check.call(File.read(profile) == retained, "happier: wrong shell-profile ownership behavior")
    calls = File.readlines(log_path).map { |line| JSON.parse(line) }
    check.call(calls.count { |call| call.first == "security" } == 3, "happier: duplicate Keychain entries survived")
    output, status = execute.call
    check.call(status.success?, "happier: absent services, credentials, and links should succeed: #{output}")

    ["launchctl:list", "launchctl:remove", "ps:-x", "security:delete-generic-password", "kill",
     "stubborn"].each do |failure|
      File.write(state_path, JSON.generate(initial_state))
      output, status = execute.call(environment.merge("ZAP_TEST_FAIL" => failure))
      expected_status = %w[kill stubborn].include?(failure) ? 1 : 50
      check.call(status.exitstatus == expected_status, "happier: #{failure} failure was swallowed: #{output}")
    end

    File.write(state_path, JSON.generate(initial_state))
    FileUtils.mkdir_p("#{fixture_home}/.bashrc")
    output, status = execute.call
    check.call(!status.success? && output.include?("Is a directory"), "happier: filesystem failure was swallowed")
  end
end
