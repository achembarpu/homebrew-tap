class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.7.0/maki-v0.7.0-aarch64-apple-darwin.tar.gz"
    sha256 "cf994a0d2ac64b5f6b38be9410602ebd2710a7924148d416ef623df41d6f7a67"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.7.0/maki-v0.7.0-x86_64-apple-darwin.tar.gz"
    sha256 "ec5a3964845f0663de268021568e7fb8b591d122d55dbeb1e559b69f43e8c904"
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
