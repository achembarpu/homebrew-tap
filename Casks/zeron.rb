cask "zeron" do
  version "0.2.54"
  sha256 "183e99ddd7a1612705c0666aad2591999549bbaf476c914d814f69ee4a5bc04a"

  url "https://github.com/zeronsh/comet/releases/download/v#{version}/zeron-#{version}-macos-arm64.dmg"
  name "Zeron"
  desc "Control coding agents locally with optional multi-device sync"
  homepage "https://github.com/zeronsh/comet"

  livecheck do
    url "https://github.com/zeronsh/comet/releases/latest"
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
