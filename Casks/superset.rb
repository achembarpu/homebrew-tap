cask "superset" do
  arch arm: "arm64", intel: "x64"

  version "1.35.0"
  sha256 arm:   "27c2d86c747c4bc7a4607cdfd871619430471c038376da45493c3e2ecbbfb1a7",
         intel: "45822fe1fd17d89f22e99e0d217c34925c2c4d77df7b39f9efb25e4d9ca98975"

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

  zap trash: [
    "~/Library/Application Support/com.superset.desktop",
    "~/Library/Caches/com.superset.desktop",
    "~/Library/Preferences/com.superset.desktop.plist",
    "~/Library/Saved Application State/com.superset.desktop.savedState",
  ]
end
