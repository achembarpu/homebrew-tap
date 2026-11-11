cask "podium" do
  arch arm: "aarch64", intel: "x64"

  version "0.3.1"
  sha256 arm:   "233c51eaa213093d850297f6a1a3eea02da0524da565e9d89c0ebcb1ff870949",
         intel: "b7d1f078ca3226b54da633b588397b10d9c0ff46120167854b43d5345174a79b"

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
