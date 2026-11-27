class Maki < Formula
  desc "Efficient AI coding agent with Lua plugins"
  homepage "https://maki.sh"
  if Hardware::CPU.arm?
    url "https://github.com/tontinton/maki/releases/download/v0.7.4/maki-v0.7.4-aarch64-apple-darwin.tar.gz"
    sha256 "d8e7bb9454225527fe48ed3f363f39d6a7603bfbdc6724aba303fa79d110a7bf"
  else
    url "https://github.com/tontinton/maki/releases/download/v0.7.4/maki-v0.7.4-x86_64-apple-darwin.tar.gz"
    sha256 "1d1a28dcc90ffce5a49cda498f6e73942768d58f01300ff319b664a08a29eebf"
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
