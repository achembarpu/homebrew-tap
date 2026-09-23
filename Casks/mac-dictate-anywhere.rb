cask "mac-dictate-anywhere" do
  version "2.12.2,44"
  sha256 "af8bbeec06f1f2d893fb9102fc989ac095077a878ab5c89e62410c71bcd2963a"

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
