cask "superset" do
  arch arm: "arm64", intel: "x64"

  version "1.33.0"
  sha256 arm:   "7d2cde87f592f4558c0914ba06dbf98887676afb6d352a9f4baa53c2cf0c268b",
         intel: "43a18fc93af33e92de5cc051f85a12bfb15f293ab8e1cd2e56d91f7aeb9ce0fb"

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
