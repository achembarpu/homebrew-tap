cask "writer-computer" do
  version "0.7.2"
  sha256 "4d86fcb67b859fc85bc93767d97fd5e7482f9e2b273ed18c905ce101cc99e974"

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
