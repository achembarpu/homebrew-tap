class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.6.4/maki-v0.6.4-aarch64-apple-darwin.tar.gz"
    sha256 "2122bf3909c44ead288d0aa9dc879eb14731d3cdda5889ccf03bf9a369f90d2c"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.6.4/maki-v0.6.4-x86_64-apple-darwin.tar.gz"
    sha256 "44966c2b0e30bafb9d71f1673924513108d454e412e3430af39c9fec668fd5a7"
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
