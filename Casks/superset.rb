cask "superset" do
  arch arm: "arm64", intel: "x64"

  version "1.38.0"
  sha256 arm:   "feacab9f74046205df0bb4c44481d6fae250f134aef8cdae77afceaa49b5193e",
         intel: "040e50edeaa349a3432cad1a00b312777cdd5b306bee62236b35c6193e83e09a"

  # The Intel release also has a versionless asset alias; keep the immutable
  # desktop-v#{version} release path as the version authority.
  artifact_name = "Superset"
  artifact_name += "-#{version}" if arch == "arm64"
  url "https://github.com/superset-sh/superset/releases/download/desktop-v#{version}/#{artifact_name}-#{arch}-mac.zip"
  name "Superset"
  desc "Agentic IDE for orchestrating coding agents"
  homepage "https://github.com/superset-sh/superset"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :monterey

  app "Superset.app"

  uninstall quit:   "com.superset.desktop",
            signal: ["TERM", "com.superset.desktop"]

  zap script: {
        executable: "/usr/bin/ruby",
        args:       ["-e", <<~'RUBY'],
          require "open3"
          home = Dir.home
          app_bundle = "Superset.app"
          state_root = File.join(home, ".superset")
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
          ["Superset Safe Storage"].each do |service|
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
        "~/.superset",
        "~/Library/Application Support/com.superset.desktop",
        "~/Library/Application Support/Superset",
        "~/Library/Caches/@supersetdesktop-updater",
        "~/Library/Caches/com.superset.desktop",
        "~/Library/Caches/com.superset.desktop.ShipIt",
        "~/Library/HTTPStorages/com.superset.desktop",
        "~/Library/HTTPStorages/com.superset.desktop.binarycookies",
        "~/Library/Logs/com.superset.desktop",
        "~/Library/Logs/Superset",
        "~/Library/Preferences/ByHost/com.superset.desktop.ShipIt.*.plist",
        "~/Library/Preferences/com.superset.desktop.plist",
        "~/Library/Saved Application State/com.superset.desktop.savedState",
        "~/Library/WebKit/com.superset.desktop",
      ]
end
