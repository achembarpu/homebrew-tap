# typed: strict
# frozen_string_literal: true

# Fakes helper shutdown and local Keychain access for cask cleanup.
module AppProcessZapFixtures
  def self.verify(token, script, temporary, check)
    bundle, state_dir, services = {
      "agent-orchestrator" => ["Agent Orchestrator.app", ".ao", ["Agent Orchestrator Safe Storage"]],
      "intent"             => ["Intent.app", "Library/Application Support/intentd", ["intent Safe Storage"]],
      "junie"              => ["junie.app", ".junie", ["junie-cli"]],
      "superset"           => ["Superset.app", ".superset", ["Superset Safe Storage"]],
    }.fetch(token)
    directory = "#{temporary}/process-#{token}"
    home = "#{directory}/home"
    FileUtils.mkdir_p(home)
    ps = "#{directory}/ps"
    security = "#{directory}/security"
    log = "#{directory}/security.log"
    File.write(ps, <<~SH)
      #!/bin/sh
      [ "$ZAP_TEST_FAIL" != ps ] || exit 50
      [ -f "$ZAP_TEST_STATE/1234" ] || printf '%s\n' '1234 #{directory}/#{bundle}/Contents/MacOS/helper'
      [ -f "$ZAP_TEST_STATE/4567" ] || printf '%s\n' '4567 #{home}/#{state_dir}/bin/helper'
      printf '%s\n' '2345 #{directory}/Other.app/Contents/MacOS/helper'
      printf '%s\n' '3456 #{home}/#{state_dir}-other/bin/helper'
    SH
    File.write(security, <<~SH)
      #!/bin/sh
      [ "$ZAP_TEST_FAIL" != security ] || exit 50
      printf '%s\n' "$3" >> "$ZAP_TEST_LOG"
      for entry in 1 2; do
        if mkdir "$ZAP_TEST_STATE/$3.$entry" 2>/dev/null; then exit 0; fi
      done
      exit 44
    SH
    [ps, security].each { |path| File.chmod(0755, path) }
    source = script.fetch(:args).fetch(1).sub("home = Dir.home", "home = #{home.inspect}")
                   .sub("/bin/ps", ps).sub("/usr/bin/security", security)
    source.prepend(<<~RUBY)
      Process.define_singleton_method(:kill) do |signal, pid|
        raise "Refusing non-fixture PID" unless [1234, 4567].include?(pid)
        path = File.join(ENV.fetch("ZAP_TEST_STATE"), pid.to_s)
        raise Errno::ESRCH if File.exist?(path)
        raise Errno::EPERM if ENV["ZAP_TEST_FAIL"] == "kill"
        next 1 if ENV["ZAP_TEST_FAIL"] == "stubborn"
        raise "Unexpected signal" unless signal == "TERM"
        File.write(path, "stopped")
      end
      def sleep(_duration); end
    RUBY
    env = { "ZAP_TEST_STATE" => directory, "ZAP_TEST_LOG" => log, "ZAP_TEST_FAIL" => "" }
    execute = ->(environment = env) { Open3.capture2e(environment, script.fetch(:executable), "-e", source) }
    output, status = execute.call
    check.call(status.success?, "#{token}: process/Keychain cleanup failed: #{output}")
    calls = File.readlines(log, chomp: true).tally
    check.call(calls.keys.sort == services.sort && calls.values.all?(3), "#{token}: wrong Keychain cleanup scope")
    output, status = execute.call
    check.call(status.success?, "#{token}: absent helpers and credentials should succeed: #{output}")
    fixture_pids = [1234, 4567]
    %w[ps security kill stubborn].each do |failure|
      fixture_pids.each { |pid| FileUtils.rm_f("#{directory}/#{pid}") }
      output, status = execute.call(env.merge("ZAP_TEST_FAIL" => failure))
      check.call(!status.success?, "#{token}: #{failure} failure was swallowed: #{output}")
    end
  end
end
