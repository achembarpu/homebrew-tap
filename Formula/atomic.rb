class Atomic < Formula
  desc "Verifiable coding agent runtime"
  homepage "https://bastani.ai/"
  if Hardware::CPU.arm?
    url "https://github.com/bastani-inc/atomic/releases/download/0.9.18/atomic-darwin-arm64.tar.gz"
    sha256 "a9ef39fdd7ebf7c55de4694c577443e9448a03db678f41dd3676d7dd15c8afcf"
  else
    url "https://github.com/bastani-inc/atomic/releases/download/0.9.18/atomic-darwin-x64.tar.gz"
    sha256 "7e29c6634ce5f83fb89d6a79bef2673217dc60090ad6c9f9b42694aec526ac3b"
  end
  license "MIT"

  livecheck do
    url "https://github.com/bastani-inc/atomic/releases"
    strategy :github_latest
  end

  depends_on :macos

  def install
    libexec.install Dir["*"]
    bin.install_symlink libexec / "atomic"
  end

  def caveats
    <<~EOS
      Atomic stores authentication, settings, sessions, and other user data
      under ~/.atomic.

      Formula uninstallation does not remove that user data. Remove it
      manually if desired:

        rm -rf ~/.atomic

      Atomic has no built-in sandbox or command-level shell permission gate.
      Run autonomous work inside a devcontainer, VM, or remote development
      machine rather than on a host with sensitive data or credentials:

        https://github.com/bastani-inc/atomic#security

      Updates are managed by `brew upgrade atomic`.
    EOS
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/atomic --version").chomp
  end
end
