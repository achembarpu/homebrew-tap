cask "junie" do
  arch arm: "aarch64", intel: "amd64"

  version "3419.7"
  sha256 arm:   "e939c8cce4b109cd6588f3b5a707e68fb712b4f8b6ea35df99451576c46d43c2",
         intel: "edf3953540d7955d1a9bc1c1f4898e4188cad73c52c7e5bc35adc917001895cc"

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
