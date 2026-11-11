cask "writer-computer" do
  version "0.8.0"
  sha256 "b651ddd976417404a85afd24684078d98c6551078691cfbafd2eee3373f37300"

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
            target=$(/usr/bin/ruby -e 'puts File.expand_path(ARGV.fetch(0), File.dirname(ARGV.fetch(1)))' "$target" "$link") || exit "$?"
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
