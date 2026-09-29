cask "superset" do
  arch arm: "arm64", intel: "x64"

  version "1.31.0"
  sha256 arm:   "f03b1915b167ec92ea037edd30544e1d5288a818c4c505a7a52f33c8c64b5964",
         intel: "f7e4f2e2a7fa5971c9f9aefc21869ed70b1069d36d0b158000d53a13aee01e7a"

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
