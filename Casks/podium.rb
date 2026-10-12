cask "podium" do
  arch arm: "aarch64", intel: "x64"

  version "0.2.0"
  sha256 arm:   "4bfc21fdbac7ebb2fb589a35b858fc102bbb1b62f2a7d63d12ba43c872c5cdd5",
         intel: "695681d08af58eef6ee1f724ac3b3c4be8c84af9539e5442efb350614c4f011c"

  url "https://github.com/madeinorbit/podium/releases/download/v#{version}/Podium_#{version}_#{arch}.dmg"
  name "Podium"
  desc "Multi-agent orchestrator for coding agents"
  homepage "https://github.com/madeinorbit/podium"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on :macos

  app "Podium.app"

  uninstall quit:   "app.podium.desktop",
            signal: ["TERM", "app.podium.desktop"]

  zap trash: [
    "~/.podium",
    "~/Library/Application Support/app.podium.desktop",
    "~/Library/Caches/app.podium.desktop",
    "~/Library/HTTPStorages/app.podium.desktop",
    "~/Library/HTTPStorages/app.podium.desktop.binarycookies",
    "~/Library/Logs/app.podium.desktop",
    "~/Library/Preferences/app.podium.desktop.plist",
    "~/Library/Saved Application State/app.podium.desktop.savedState",
    "~/Library/WebKit/app.podium.desktop",
  ]

  caveats <<~EOS
    Podium runs agent CLIs through persistent terminal sessions. Install and
    authenticate the agent CLIs you want to use separately.
  EOS
end
