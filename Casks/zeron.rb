cask "zeron" do
  version "0.2.90"
  sha256 "6d4645bff25e1ec3afb95936257e87aa72ef5478a4ec5ef6f42d3f3b64f2e6f3"

  url "https://github.com/zeronsh/zeron/releases/download/v#{version}/zeron-#{version}-macos-arm64.dmg"
  name "Zeron"
  desc "Control coding agents locally with optional multi-device sync"
  homepage "https://github.com/zeronsh/zeron"

  livecheck do
    url "https://github.com/zeronsh/zeron/releases/latest"
    strategy :github_latest
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on macos: :monterey

  app "Zeron.app"

  zap trash: "~/.zeron"

  caveats <<~EOS
    Zeron can optionally sync workspaces across trusted devices. A synced
    device can read and write the files in workspaces you expose to it.

    Zeron includes an in-app updater; use Homebrew to update this cask when
    you want Homebrew to remain the source of the installed version.
  EOS
end
