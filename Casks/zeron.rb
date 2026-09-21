cask "zeron" do
  version "0.2.81"
  sha256 "9543c6e856ba36065503c9aec84b1ffff22b5f350259eab3e1adfb75057780f8"

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
