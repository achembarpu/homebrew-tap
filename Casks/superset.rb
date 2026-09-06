cask "superset" do
  arch arm: "arm64", intel: "x64"

  version "1.26.0"
  sha256 arm:   "ee1fe264a65aac26835055683cd6b2ecc6724c253ada3466c4a5c93c9d88dd9f",
         intel: "07a77799a0a6f104ad65316fe9f2b8a7bdded1399a9621b2d975018797f1402d"

  url "https://github.com/superset-sh/superset/releases/download/desktop-v#{version}/Superset-#{version}-#{arch}-mac.zip"
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

  zap trash: [
    "~/Library/Application Support/com.superset.desktop",
    "~/Library/Caches/com.superset.desktop",
    "~/Library/Preferences/com.superset.desktop.plist",
    "~/Library/Saved Application State/com.superset.desktop.savedState",
  ]
end
