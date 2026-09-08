cask "junie" do
  arch arm: "aarch64", intel: "amd64"

  version "3110.6"
  sha256 arm:   "3ca79a6a59c4866460294efce63838f5d89b81ecbb3c74d2ff2299b063e17292",
         intel: "58caa4fc0d5c8faf357ff3e4ac96a93e1c3275cf9c105bcd9ea1c0fb438d2083"

  url "https://github.com/JetBrains/junie/releases/download/#{version}/junie-release-#{version}-macos-#{arch}.zip"
  name "Junie"
  desc "AI coding agent CLI by JetBrains"
  homepage "https://www.jetbrains.com/junie/"

  # The GitHub latest release is a nightly build, not the stable release
  # channel used by this cask. Check JetBrains' stable update manifest instead.
  livecheck do
    url "https://raw.githubusercontent.com/jetbrains-junie/junie/main/update-info.jsonl"
    regex(/"version":"(\d+(?:\.\d+)+)".*"platform":"macos-aarch64"/)
    strategy :page_match
  end

  depends_on :macos

  app "Applications/junie.app"
  binary "#{appdir}/junie.app/Contents/MacOS/junie"

  zap trash: [
    "~/.junie",
    "~/.local/share/junie",
  ]

  caveats <<~EOS
    Junie ships Developer ID signed and notarized; no re-sign needed. The
    binary linked onto PATH lives inside the app bundle.

    Updates come from `brew upgrade --cask junie`. Junie's built-in
    self-updater expects JetBrains' own shim layout (~/.local/bin/junie),
    which this cask does not install.
  EOS
end
