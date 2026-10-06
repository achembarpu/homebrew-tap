cask "tuicommander" do
  version "1.7.6"
  sha256 "0f7b911b5ee615bdfd72bd4c943c7c167aea89dc3bf48695abb5525c631deca3"

  url "https://github.com/sstraus/tuicommander/releases/download/v#{version}/TUICommander_#{version}_aarch64.dmg"
  name "TUICommander"
  desc "AI-native IDE for orchestrating coding agents"
  homepage "https://github.com/sstraus/tuicommander"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on :macos

  app "TUICommander.app"

  uninstall quit:   "com.tuic.commander",
            signal: ["TERM", "com.tuic.commander"]

  zap script: {
        executable: "/bin/sh",
        args:       ["-c", <<~SH],
          for service in tuicommander tuicommander-ai-chat tuicommander-llm-api tuicommander-github; do
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
      trash:  [
        "/usr/local/bin/tuic",
        "~/.tuicommander",
        "~/Library/Application Support/com.tuic.commander",
        "~/Library/Application Support/tui-commander",
        "~/Library/Application Support/tuicommander",
        "~/Library/Caches/com.tuic.commander",
        "~/Library/HTTPStorages/com.tuic.commander",
        "~/Library/HTTPStorages/com.tuic.commander.binarycookies",
        "~/Library/Logs/com.tuic.commander",
        "~/Library/Preferences/com.tuic.commander.plist",
        "~/Library/Saved Application State/com.tuic.commander.savedState",
        "~/Library/WebKit/com.tuic.commander",
      ]
end
