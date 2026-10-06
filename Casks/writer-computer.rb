cask "writer-computer" do
  version "0.7.3"
  sha256 "dffaf883553db54dde42df7dcaf24ed8b10f899d41b6e97fc66012817f92038e"

  url "https://github.com/joelbqz/writer-computer/releases/download/v#{version}/Writer_#{version}_aarch64.dmg"
  name "Writer"
  desc "Native Markdown writing environment"
  homepage "https://github.com/joelbqz/writer-computer"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on arch: :arm64
  depends_on :macos

  app "Writer.app"

  uninstall quit:   "com.writer-computer",
            signal: ["TERM", "com.writer-computer"]

  zap script: {
        executable: "/bin/sh",
        args:       ["-c", <<~SH],
          link="/usr/local/bin/writer"
          if [ -L "$link" ]; then
            target=$(/usr/bin/readlink "$link") || exit "$?"
            case "$target" in
              */Writer.app/Contents/*) /bin/rm -- "$link" ;;
            esac
          fi
        SH
        sudo:       true,
      },
      trash:  [
        "~/Library/Application Support/com.writer-computer",
        "~/Library/Caches/com.writer-computer",
        "~/Library/HTTPStorages/com.writer-computer",
        "~/Library/HTTPStorages/com.writer-computer.binarycookies",
        "~/Library/Logs/com.writer-computer",
        "~/Library/Preferences/com.writer-computer.plist",
        "~/Library/Saved Application State/com.writer-computer.savedState",
        "~/Library/WebKit/com.writer-computer",
      ]
end
