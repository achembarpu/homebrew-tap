class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.7.2/maki-v0.7.2-aarch64-apple-darwin.tar.gz"
    sha256 "de286c993de103ce85d0be08681e7baad57731fe094874273c3972749c7820d4"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.7.2/maki-v0.7.2-x86_64-apple-darwin.tar.gz"
    sha256 "805fdd641b00798c94db7c4a6bf1f1bfaa60802d533da5683d391585eddb4759"
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
