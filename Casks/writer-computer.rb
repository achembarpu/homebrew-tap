cask "writer-computer" do
  version "0.6.1"
  sha256 "edebd387b24196d6a5ee0fe6d28ba34511fc57bb42e64f3801f47a9c6d2b2eb6"

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
