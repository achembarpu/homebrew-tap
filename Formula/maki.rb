class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.6.1/maki-v0.6.1-aarch64-apple-darwin.tar.gz"
    sha256 "ed9262715d88ea585814b97bda123274d830e8571b27bfd03c6d29760e274da6"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.6.1/maki-v0.6.1-x86_64-apple-darwin.tar.gz"
    sha256 "fa33cda6126449833e49f04d5a07e88b2bbd0e711d1d0b87fb467cc17ab2f251"
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
