class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.5.7/maki-v0.5.7-aarch64-apple-darwin.tar.gz"
    sha256 "f84725c29a34412d920879a24872202f8c0d679f7d28fbe41471ad18e1543523"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.5.7/maki-v0.5.7-x86_64-apple-darwin.tar.gz"
    sha256 "caf4dbd33fbb3dca482a5bfb5f96afb56f77e17108077a0dc7061f2e96225b9f"
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
