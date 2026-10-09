cask "zeron" do
  version "0.2.107"
  sha256 "afed2900b97d71492613dc1580e83cebfae9bc27c29c3b39be9c09b722ad410e"

  url "https://github.com/zeronsh/zeron/releases/download/v#{version}/zeron-#{version}-macos-arm64.dmg"
  name "Zeron"
  desc "Control coding agents locally with optional multi-device sync"
  homepage "https://github.com/zeronsh/zeron"

  livecheck do
    url "https://github.com/zeronsh/zeron/releases/latest"
    strategy :github_latest
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :monterey

  app "Zeron.app"

  uninstall quit:   "sh.zeron.app",
            signal: ["TERM", "sh.zeron.app"]

  zap trash: [
    "~/.zeron",
    "~/Library/Caches/sh.zeron.app",
    "~/Library/HTTPStorages/sh.zeron.app",
    "~/Library/HTTPStorages/sh.zeron.app.binarycookies",
    "~/Library/Logs/sh.zeron.app",
    "~/Library/Preferences/sh.zeron.app.plist",
    "~/Library/Saved Application State/sh.zeron.app.savedState",
    "~/Library/WebKit/sh.zeron.app",
  ]

  caveats <<~EOS
    Zeron can optionally sync workspaces across trusted devices. A synced
    device can read and write the files in workspaces you expose to it.

    Zeron includes an in-app updater; use Homebrew to update this cask when
    you want Homebrew to remain the source of the installed version.
  EOS
end
