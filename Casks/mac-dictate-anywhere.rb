cask "mac-dictate-anywhere" do
  version "2.12.3,45"
  sha256 "637889198e83625c32f36e682fa2cf3f71dd6ba942bb3c481b1f0b969d797988"

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
