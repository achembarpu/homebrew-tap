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

  zap trash: [
    "~/Library/Application Support/com.writer-computer",
    "~/Library/Caches/com.writer-computer",
    "~/Library/Preferences/com.writer-computer.plist",
    "~/Library/Saved Application State/com.writer-computer.savedState",
  ]
end
