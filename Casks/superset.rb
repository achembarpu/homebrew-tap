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

  zap trash: [
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
    "~/Library/Preferences/com.superset.desktop.plist",
    "~/Library/Saved Application State/com.superset.desktop.savedState",
    "~/Library/WebKit/com.superset.desktop",
  ]
end
