class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.5.4/maki-v0.5.4-aarch64-apple-darwin.tar.gz"
    sha256 "662f851a2342204892a32cfecde95590d2b88e24e26ee5775cd850532996250a"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.5.4/maki-v0.5.4-x86_64-apple-darwin.tar.gz"
    sha256 "7d220a914a914aa301070665f274418a0dfb4ad7ee22434e3494c989851e7ef0"
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
