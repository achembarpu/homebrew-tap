class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.7.3/maki-v0.7.3-aarch64-apple-darwin.tar.gz"
    sha256 "f336adffaf16eb9d51620368fe41c9f776e418ddb48bcf4727e75a1ecbf77afa"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.7.3/maki-v0.7.3-x86_64-apple-darwin.tar.gz"
    sha256 "ba6bf9f71b4914419e0e05a32fd738fa01a325d02a4f49dcc0486eefe1295c4c"
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
