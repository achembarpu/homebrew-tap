class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.6.2/maki-v0.6.2-aarch64-apple-darwin.tar.gz"
    sha256 "58c49ef7f2af8a7b77d4d27f8a42da78c7dc97ebf8e02082d3339b51fc8192b5"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.6.2/maki-v0.6.2-x86_64-apple-darwin.tar.gz"
    sha256 "6e7b6be988fa1d1750e24ed3528fe35754254764808a63f1146f9f71f662ea77"
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
