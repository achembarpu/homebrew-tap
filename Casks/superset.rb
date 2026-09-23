cask "superset" do
  arch arm: "arm64", intel: "x64"

  version "1.30.2"
  sha256 arm:   "751f326384bdaca23a518562380626546e46e005eeef91982f01d48ef222e214",
         intel: "dd3aeceef192b20524fa831e2463aef8f66fadc791430fc084c1d4cb7368f911"

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
