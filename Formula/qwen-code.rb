class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.25.0/qwen-code-darwin-arm64.tar.gz"
    sha256 "6fd20e1f817277d597d43f6496b2d2d446b7a011a3e1475b9b846c6de32848d7"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.25.0/qwen-code-darwin-x64.tar.gz"
    sha256 "1159e0e53b51e852c8fb3a44000ae394973c0e57865f639b632d9a4ddd154d6f"
  end
  license "Apache-2.0"

  livecheck do
    url "https://github.com/QwenLM/qwen-code.git"
    regex(/^v(\d+(?:\.\d+)+)$/i)
    strategy :git
  end

  depends_on :macos

  def install
    libexec.install Dir["*"]
    bin.write_exec_script libexec / "bin/qwen"
  end

  def caveats
    <<~EOS
      Qwen Code stores authentication and settings under ~/.qwen. It may also
      create project-local .qwen directories.

      Formula uninstallation does not remove that user data. Remove the
      global settings manually if desired:

        rm -rf ~/.qwen

      Project-local .qwen directories are not managed by Homebrew.
      Updates are managed by `brew upgrade qwen-code`.
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/qwen --version").chomp
  end
end
