class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.6.5/maki-v0.6.5-aarch64-apple-darwin.tar.gz"
    sha256 "678fe77bb6c202f477a9f7897ed55b27bc71187d2da7edf428775f6a401ae7b8"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.6.5/maki-v0.6.5-x86_64-apple-darwin.tar.gz"
    sha256 "e00068a885a7012dd7d03f3c1fe4794bf5699672b8fad229a75115cae6e43c31"
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
