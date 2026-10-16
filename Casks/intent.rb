cask "intent" do
  arch arm: "arm64", intel: "x64"

  version "2.201.1"
  sha256 arm:   "02c88011f10fe9306834a875ba93d43af58ad19253e7907b16fcccb2e8346004",
         intel: "d0a1d3294b3a06b009729159f99a1241fb72a0075233d8cb04192599565c5d22"

  url "https://github.com/intent-hq/cloudlands-releases/releases/download/v#{version}/Intent-#{version}-#{arch}-mac.zip"
  name "Intent"
  desc "Desktop workspace for coordinating AI coding agents"
  homepage "https://intentapp.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :ventura

  app "Intent.app"

  uninstall quit:   "app.cloudlands.intent",
            signal: ["TERM", "app.cloudlands.intent"]

  zap script: {
        executable: "/usr/bin/ruby",
        args:       ["-e", <<~'RUBY'],
          require "open3"
          home = Dir.home
          app_bundle = "Intent.app"
          state_root = File.join(home, "Library/Application Support/intentd")
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
          ["intent Safe Storage"].each do |service|
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
        "~/Library/Application Support/Intent",
        "~/Library/Application Support/intent-cloudlands",
        "~/Library/Application Support/intentd",
        "~/Library/Caches/app.cloudlands.intent",
        "~/Library/Caches/app.cloudlands.intent.ShipIt",
        "~/Library/Caches/intent-updater",
        "~/Library/HTTPStorages/app.cloudlands.intent",
        "~/Library/HTTPStorages/app.cloudlands.intent.binarycookies",
        "~/Library/Logs/app.cloudlands.intent",
        "~/Library/Logs/Intent",
        "~/Library/Preferences/app.cloudlands.intent.plist",
        "~/Library/Preferences/ByHost/app.cloudlands.intent.ShipIt.*.plist",
        "~/Library/Saved Application State/app.cloudlands.intent.savedState",
        "~/Library/WebKit/app.cloudlands.intent",
      ]

  caveats <<~EOS
    Intent requires a configured agent provider. It prompts to install Git and
    Node.js 22 or later if they are missing.

    Intent includes an automatic updater. To update through Homebrew, run
    `brew upgrade --cask intent`.

    Uninstalling with --zap removes settings and the intentd daemon
    data, including workspaces, notes, tasks, and agent sessions. It removes the
    local Electron encryption key. Cross-device iCloud backend and guest-session
    records remain; use Intent's Forget action to remove those records.
  EOS
end
