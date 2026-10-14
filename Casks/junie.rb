cask "junie" do
  arch arm: "aarch64", intel: "amd64"

  version "3659.4"
  sha256 arm:   "b426bcb7546cd90ff52177b9240f85ce17378de28fa0191287fcef6a8790ea2a",
         intel: "48c0e416effdcdcfade0a38e56009a5d6f9cdaf6d6e65c1d197bca40cca3548e"

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

  uninstall quit:   "com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
            signal: ["TERM", "com.intellij.ml.llm.matterhorn.ej.app.cli.standalone"]

  zap trash: [
    "~/.junie",
    "~/.local/share/junie",
    "~/Library/Caches/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
    "~/Library/HTTPStorages/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
    "~/Library/HTTPStorages/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone.binarycookies",
    "~/Library/Logs/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
    "~/Library/Preferences/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone.plist",
    "~/Library/Saved Application State/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone.savedState",
    "~/Library/WebKit/com.intellij.ml.llm.matterhorn.ej.app.cli.standalone",
  ]

  caveats <<~EOS
    Junie ships Developer ID signed and notarized; no re-sign needed. The
    binary linked onto PATH lives inside the app bundle.

    Updates come from `brew upgrade --cask junie`. Junie's built-in
    self-updater expects JetBrains' own shim layout (~/.local/bin/junie),
    which this cask does not install.
  EOS
end
