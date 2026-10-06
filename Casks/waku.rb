cask "waku" do
  version "0.1.20"
  sha256 "b01d0cbc3cc6f4e4717d4be56e2f58b46114ad2f9439cf28a228e4a7585e53ce"

  url "https://github.com/egoist/waku/releases/download/v#{version}/Waku-#{version}.dmg"
  name "Waku"
  desc "Native app for local coding agents"
  homepage "https://waku.sh/"

  livecheck do
    url "https://releases.waku.sh/appcast.xml"
    strategy :sparkle, &:short_version
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :ventura

  app "Waku.app"

  uninstall quit:   "sh.waku",
            signal: ["TERM", "sh.waku"]

  zap trash: [
    "~/.waku",
    "~/Library/Application Support/Waku",
    "~/Library/Caches/sh.waku",
    "~/Library/Caches/Waku",
    "~/Library/HTTPStorages/sh.waku",
    "~/Library/HTTPStorages/sh.waku.binarycookies",
    "~/Library/Logs/sh.waku",
    "~/Library/Preferences/sh.waku.plist",
    "~/Library/Saved Application State/sh.waku.savedState",
    "~/Library/WebKit/sh.waku",
  ]
end
