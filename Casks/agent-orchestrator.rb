cask "agent-orchestrator" do
  arch arm: "arm64", intel: "x64"

  version "0.15.1"
  sha256 arm:   "7be6fb7b9b3c031525872c155542dcd19670c6d9b78e2e70e1aa2640a0851df9",
         intel: "6d810d40be801104409d01ee50b3f685595708def8bace3f1c154f83c6781ddc"

  url "https://github.com/Untrivial-ai/agent-orchestrator/releases/download/v#{version}/agent-orchestrator-darwin-#{arch}.zip"
  name "Agent Orchestrator"
  desc "Desktop workspace for orchestrating coding agents"
  homepage "https://github.com/Untrivial-ai/agent-orchestrator"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true

  # The 0.14.9 release raised the app's minimum macOS version.
  if Version.new(version.to_s) >= Version.new("0.14.9")
    depends_on macos: :ventura
  else
    depends_on :macos
  end

  app "Agent Orchestrator.app"

  uninstall quit:   "dev.agent-orchestrator.desktop",
            signal: ["TERM", "dev.agent-orchestrator.desktop"]

  zap script: {
        executable: "/usr/bin/ruby",
        args:       ["-e", <<~'RUBY'],
          require "open3"
          home = Dir.home
          app_bundle = "Agent Orchestrator.app"
          state_root = File.join(home, ".ao")
          output, status = Open3.capture2e("/bin/ps", "-x", "-o", "pid=,comm=")
          abort output unless status.success?
          output.each_line do |line|
            pid, executable = line.strip.split(/\s+/, 2)
            next unless pid && pid.to_i > 1 && pid.to_i != Process.pid && executable
            next unless executable.include?("/" + app_bundle + "/Contents/") ||
                        executable.start_with?(state_root + "/")

            begin
              Process.kill("TERM", pid.to_i)
            rescue Errno::ESRCH
              next
            end
            50.times do
              begin
                Process.kill(0, pid.to_i)
              rescue Errno::ESRCH
                break
              end
              sleep 0.1
            end
            begin
              Process.kill(0, pid.to_i)
              abort "App helper #{pid} did not stop; refusing to remove its data"
            rescue Errno::ESRCH
              nil
            end
          end
          ["Agent Orchestrator Safe Storage"].each do |service|
            loop do
              output, status = Open3.capture2e("/usr/bin/security", "delete-generic-password", "-s", service)
              break if status.exitstatus == 44
              next if status.success?

              warn output
              exit(status.exitstatus || 1)
            end
          end
        RUBY
        sudo:       false,
      },
      trash:  [
        "~/.ao",
        "~/Library/Application Support/Agent Orchestrator",
        "~/Library/Caches/agent-orchestrator-updater",
        "~/Library/Caches/dev.agent-orchestrator.desktop",
        "~/Library/Caches/dev.agent-orchestrator.desktop.ShipIt",
        "~/Library/HTTPStorages/dev.agent-orchestrator.desktop",
        "~/Library/HTTPStorages/dev.agent-orchestrator.desktop.binarycookies",
        "~/Library/Logs/Agent Orchestrator",
        "~/Library/Logs/dev.agent-orchestrator.desktop",
        "~/Library/Preferences/ByHost/dev.agent-orchestrator.desktop.ShipIt.*.plist",
        "~/Library/Preferences/dev.agent-orchestrator.desktop.plist",
        "~/Library/Saved Application State/dev.agent-orchestrator.desktop.savedState",
        "~/Library/WebKit/dev.agent-orchestrator.desktop",
      ]

  caveats <<~EOS
    Agent Orchestrator starts a local daemon and runs the coding agent CLIs
    that you configure separately.

    The production app enables remote product telemetry. See the upstream
    telemetry documentation for details.
  EOS
end
