class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.5.3/maki-v0.5.3-aarch64-apple-darwin.tar.gz"
    sha256 "edf90814ffbd003196de54ecd2e12ea76dec4aa9f869e092890e1d1ed7419179"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.5.3/maki-v0.5.3-x86_64-apple-darwin.tar.gz"
    sha256 "328beab7ec9035f49b3567d2498d0ff618faa1a341e8a71b9440d44eb254b7d5"
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
