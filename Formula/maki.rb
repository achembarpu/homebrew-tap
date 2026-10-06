class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.6.0/maki-v0.6.0-aarch64-apple-darwin.tar.gz"
    sha256 "654f5f05e71d28fa50e3af287117a5c2ca55f8b84cde972c7aa1cb732817b1e4"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.6.0/maki-v0.6.0-x86_64-apple-darwin.tar.gz"
    sha256 "2a683575060db9dc2cd68c243184f6732943ca1bd8e00279f8756e2f5dfbc23f"
  end
  license "MIT"

  livecheck do
    url "https://github.com/tontinton/maki/releases/latest"
    strategy :github_latest
  end

  depends_on :macos

  def install
    bin.install "maki"
  end

  def caveats
    <<~EOS
      Maki stores configuration, sessions, and other user data under
      ~/.config/maki and ~/.local/share/maki.

      Formula uninstallation does not remove that user data. Remove it
      manually if desired:

        rm -rf ~/.config/maki ~/.local/share/maki

      Updates are managed by `brew upgrade maki`.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/maki --version").chomp
  end
end
