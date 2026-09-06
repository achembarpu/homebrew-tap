class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.5.1/maki-v0.5.1-aarch64-apple-darwin.tar.gz"
    sha256 "6011d7f7045110192aa94f4f493fe02471b3f11d5dff3c3173c6dcc2a661e113"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.5.1/maki-v0.5.1-x86_64-apple-darwin.tar.gz"
    sha256 "e8b429b1b2fbdf6bc33101f93659ae1721ab4e1477ec63de2c2134b51068dc6f"
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
