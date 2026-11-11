class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.26.7/qwen-code-darwin-arm64.tar.gz"
    sha256 "543b3a3e2caa8321720a8f8171fe7b28f4646e9abff2e79f0f19d9e82e2e9208"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.26.7/qwen-code-darwin-x64.tar.gz"
    sha256 "8d7fe58b4f2a492fd40166e4c321e3b45eeb295657fceb114fe0f8f48eaa9691"
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
