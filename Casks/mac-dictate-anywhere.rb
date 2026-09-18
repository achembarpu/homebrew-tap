cask "mac-dictate-anywhere" do
  version "2.11.0,41"
  sha256 "9a9e54003ba148b8973bb8f1fb84bbbf3dbcb207665cc03b250f421eb8b1ce8d"

  url "https://github.com/hoomanaskari/mac-dictate-anywhere/releases/download/v#{version.csv.first}/DictateAnywhere-#{version.csv.first}.zip"
  name "Dictate Anywhere"
  desc "On-device voice dictation for any app"
  homepage "https://github.com/hoomanaskari/mac-dictate-anywhere"

  livecheck do
    url "https://raw.githubusercontent.com/hoomanaskari/mac-dictate-anywhere/main/appcast.xml"
    strategy :sparkle
  end

  auto_updates true
  depends_on macos: :sonoma

  app "Dictate Anywhere.app"

  zap trash: [
    "~/Library/Preferences/com.pixelforty.dictate-anywhere.plist",
    "~/Library/Saved Application State/com.pixelforty.dictate-anywhere.savedState",
  ]

  caveats <<~EOS
    Dictate Anywhere requires Microphone and Accessibility permissions. Grant
    both permissions in System Settings → Privacy & Security before dictating.

    Speech models are stored in the shared FluidAudio model directory and are
    not removed by uninstall.
  EOS
end
