class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.7.1/maki-v0.7.1-aarch64-apple-darwin.tar.gz"
    sha256 "60561c7c84faa015c2694b47064cd927dfdd244f6ee5909a83e337516daea1c9"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.7.1/maki-v0.7.1-x86_64-apple-darwin.tar.gz"
    sha256 "cee8f8ce0640284eec11c2a4d3805286201e0c7729737ae9459d31c7cded92d2"
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
