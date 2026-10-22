cask "junie" do
  arch arm: "aarch64", intel: "amd64"

  version "3813.7"
  sha256 arm:   "36f11ca9946add48a2a41cce9edaf2ca975c1443b5f11251beafb4e8718872ca",
         intel: "a1e095ad98fb73501f12e7938b8758a390a41d0a714c4b62e8e66c9b2a1397fe"

  url "https://github.com/JetBrains/junie/releases/download/#{version}/junie-release-#{version}-macos-#{arch}.zip"
  name "Junie"
  desc "AI coding agent CLI by JetBrains"
  homepage "https://www.jetbrains.com/junie/"

  # The GitHub latest release is a nightly build, not the stable release
  # channel used by this cask. Check JetBrains' stable update manifest instead.
  livecheck do
    url "https://raw.githubusercontent.com/jetbrains-junie/junie/main/update-info.jsonl"
    regex(/"version":"(\d+(?:\.\d+)+)".*"platform":"macos-aarch64"/)
    strategy :page_match
  end

  depends_on :macos

  app "Applications/junie.app"
  binary "#{appdir}/junie.app/Contents/MacOS/junie"

  uninstall quit:   "com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
            signal: ["TERM", "com.intellij.ml.llm.matterhorn.ej.app.cli.standalone"]

  zap script: {
        executable: "/usr/bin/ruby",
        args:       ["-e", <<~'RUBY'],
          require "open3"
          home = Dir.home
          app_bundle = "junie.app"
          state_root = File.join(home, ".junie")
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
          ["junie-cli"].each do |service|
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
        "~/.junie",
        "~/.local/share/junie",
        "~/Library/Caches/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
        "~/Library/HTTPStorages/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
        "~/Library/HTTPStorages/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone.binarycookies",
        "~/Library/Logs/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
        "~/Library/Preferences/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone.plist",
        "~/Library/Saved Application State/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone.savedState",
        "~/Library/WebKit/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
      ]

  caveats <<~EOS
    Junie ships Developer ID signed and notarized; no re-sign needed. The
    binary linked onto PATH lives inside the app bundle.

    Updates come from `brew upgrade --cask junie`. Junie's built-in
    self-updater expects JetBrains' own shim layout (~/.local/bin/junie),
    which this cask does not install.
  EOS
end
