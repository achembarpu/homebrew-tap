cask "waku" do
  version "0.1.19"
  sha256 "b4dbfb6377be68ab8649cf8063cdae0156dc6f5a862c1c0ba77b4d6157e3d406"

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

  zap trash: [
    "~/.waku",
    "~/Library/Application Support/Waku",
    "~/Library/Caches/sh.waku",
    "~/Library/Caches/Waku",
    "~/Library/HTTPStorages/sh.waku",
    "~/Library/HTTPStorages/sh.waku.binarycookies",
    "~/Library/Preferences/sh.waku.plist",
    "~/Library/Saved Application State/sh.waku.savedState",
    "~/Library/WebKit/sh.waku",
  ]
end
