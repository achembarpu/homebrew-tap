class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.5.5/maki-v0.5.5-aarch64-apple-darwin.tar.gz"
    sha256 "05a7f379204cfc0615f73604b53ec295392c8bb21a63b1c0560e9164521d597c"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.5.5/maki-v0.5.5-x86_64-apple-darwin.tar.gz"
    sha256 "175d56d894e93c3f71ed1d4ccb9bcdf43a9078e8d4a25b712f43933893c061d0"
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
