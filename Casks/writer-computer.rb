cask "writer-computer" do
  version "0.6.0"
  sha256 "9cb842a0c9aee788c9f474474b66ba25e9e25f7682887a0d6a24fb4642d83d36"

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
