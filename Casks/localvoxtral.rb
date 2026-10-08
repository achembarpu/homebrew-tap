cask "localvoxtral" do
  version "0.14.0"
  sha256 "45cf304178753ef82a1aa424aee3de063556557214996c9c1b7ae9b2442f87fc"

  url "https://github.com/T0mSIlver/localvoxtral/releases/download/v#{version}/localvoxtral-v#{version}.zip"
  name "localvoxtral"
  desc "Realtime, fully local dictation for the menu bar"
  homepage "https://github.com/T0mSIlver/localvoxtral"

  livecheck do
    url "https://github.com/T0mSIlver/localvoxtral/releases/latest"
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :sequoia

  app "localvoxtral.app"

  # Releases are ad-hoc signed, not notarized. The official installer clears
  # quarantine and re-signs locally before the bundle enters /Applications;
  # replicate that here so first launch works on macOS 15 and macOS 26 alike
  # (macOS 26 can hang on a foreign ad-hoc signature during Gatekeeper's
  # first-exec scan unless the bundle is re-signed locally).
  postflight_steps do
    run "/usr/bin/xattr", args: ["-cr", "{{appdir}}/localvoxtral.app"]
    run "/usr/bin/codesign",
        args: ["--force", "--deep", "--sign", "-", "{{appdir}}/localvoxtral.app"]
  end

  uninstall launchctl: "com.localvoxtral.login",
            quit:      "com.localvoxtral.app",
            signal:    ["TERM", "com.localvoxtral.app"]

  zap launchctl: "com.localvoxtral.login",
      script:    {
        executable: "/bin/sh",
        args:       ["-c", <<~SH],
          for service in com.localvoxtral.api-keys com.localvoxtral.app.cmux-socket; do
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
      trash:     [
        "~/.cache/huggingface/hub/.locks/models--mlx-community--nemotron-3.5-asr-streaming-0.6b-8bit",
        "~/.cache/huggingface/hub/.locks/models--mlx-community--Qwen3.5-0.8B-8bit",
        "~/.cache/huggingface/hub/.locks/models--mlx-community--Qwen3.5-4B-OptiQ-4bit",
        "~/.cache/huggingface/hub/.locks/models--mlx-community--Qwen3.5-9B-OptiQ-4bit",
        "~/.cache/huggingface/hub/.locks/models--T0mSIlver--Voxtral-Mini-4B-Realtime-2602-4bit-qhead",
        "~/.cache/huggingface/hub/models--mlx-community--nemotron-3.5-asr-streaming-0.6b-8bit",
        "~/.cache/huggingface/hub/models--mlx-community--Qwen3.5-0.8B-8bit",
        "~/.cache/huggingface/hub/models--mlx-community--Qwen3.5-4B-OptiQ-4bit",
        "~/.cache/huggingface/hub/models--mlx-community--Qwen3.5-9B-OptiQ-4bit",
        "~/.cache/huggingface/hub/models--T0mSIlver--Voxtral-Mini-4B-Realtime-2602-4bit-qhead",
        "~/Library/Application Support/localvoxtral",
        "~/Library/Caches/com.localvoxtral.app",
        "~/Library/Containers/com.localvoxtral.app.widgets",
        "~/Library/HTTPStorages/com.localvoxtral.app",
        "~/Library/HTTPStorages/com.localvoxtral.app.binarycookies",
        "~/Library/LaunchAgents/com.localvoxtral.login.plist",
        "~/Library/Logs/com.localvoxtral.app",
        "~/Library/Preferences/com.localvoxtral.app.plist",
        "~/Library/Saved Application State/com.localvoxtral.app.savedState",
        "~/Library/WebKit/com.localvoxtral.app",
      ]

  caveats <<~EOS
    macOS may silently drop the Accessibility grant after the app bundle is
    replaced (updates). If the dictation hotkey stops working, toggle
    localvoxtral off and on in System Settings → Privacy & Security →
    Accessibility.

    First launch runs a setup wizard: microphone + Accessibility permissions
    and a one-time engine/model download from Hugging Face.
  EOS
end
