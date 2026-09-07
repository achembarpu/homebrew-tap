class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.5.2/maki-v0.5.2-aarch64-apple-darwin.tar.gz"
    sha256 "d2cb3b77d865d3476a95cd0faddb53700f2d2550da75b0ad90c11a6d7f8187a4"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.5.2/maki-v0.5.2-x86_64-apple-darwin.tar.gz"
    sha256 "40a52e00ef9c021b5d458ddc556bae83acd71a3066ed92df3f31437fcce4d7f1"
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
