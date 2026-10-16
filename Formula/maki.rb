class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.6.3/maki-v0.6.3-aarch64-apple-darwin.tar.gz"
    sha256 "ebf4b163cb3df95c775c713d2c03b49fc371cff19c81d183c11ed48ee91fcc60"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.6.3/maki-v0.6.3-x86_64-apple-darwin.tar.gz"
    sha256 "f6ae22741a46cbdad16672cc3ba0376b2b1c725a5e3b36fe6ab6840a48de5737"
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
