cask "superset" do
  arch arm: "arm64", intel: "x64"

  version "1.36.0"
  sha256 arm:   "37e33b5c7caa974fe23b394d65c414e5c6233430fa08be148a926f4d5a7eab94",
         intel: "32c8465021b57fc7d9f9618f9029bf4d710fd4191aa242f66d9483a80cd0fe3c"

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
