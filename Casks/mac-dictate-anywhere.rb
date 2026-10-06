cask "mac-dictate-anywhere" do
  version "2.12.6,48"
  sha256 "b5fa1fda765df8dcba66aa73451f1486f01a935aa08481eedaa8d60206b01eda"

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

  uninstall quit:   "com.pixelforty.dictate-anywhere",
            signal: ["TERM", "com.pixelforty.dictate-anywhere"]

  zap script: {
        executable: "/bin/sh",
        args:       ["-c", <<~SH],
          for service in com.pixelforty.dictate-anywhere.openrouter com.pixelforty.dictate-anywhere.openai-compatible com.pixelforty.dictate-anywhere.assemblyai; do
            while :; do
              output=$(/usr/bin/security delete-generic-password -s "$service" 2>&1)
              status=$?
              case "$status" in
                0) ;;
                44) break ;; # The item is already absent.
                *) printf '%s\n' "$output" >&2; exit "$status" ;;
              esac
            done
          done
        SH
        sudo:       false,
      },
      trash:  [
        "~/Library/Application Support/Dictate Anywhere",
        "~/Library/Application Support/FluidAudio",
        "~/Library/Caches/com.pixelforty.dictate-anywhere",
        "~/Library/HTTPStorages/com.pixelforty.dictate-anywhere",
        "~/Library/HTTPStorages/com.pixelforty.dictate-anywhere.binarycookies",
        "~/Library/Logs/com.pixelforty.dictate-anywhere",
        "~/Library/Preferences/com.pixelforty.dictate-anywhere.plist",
        "~/Library/Saved Application State/com.pixelforty.dictate-anywhere.savedState",
        "~/Library/WebKit/com.pixelforty.dictate-anywhere",
      ]

  caveats <<~EOS
    Dictate Anywhere requires Microphone and Accessibility permissions. Grant
    both permissions in System Settings → Privacy & Security before dictating.

    Uninstalling with --zap also removes downloaded speech models, including
    the shared FluidAudio model directory.
  EOS
end
