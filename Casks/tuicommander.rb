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
  depends_on :macos
  depends_on arch: :arm64

  app "TUICommander.app"

  zap trash: [
    "~/Library/Application Support/com.tuic.commander",
    "~/Library/Caches/com.tuic.commander",
    "~/Library/Preferences/com.tuic.commander.plist",
    "~/Library/Saved Application State/com.tuic.commander.savedState",
  ]
end
