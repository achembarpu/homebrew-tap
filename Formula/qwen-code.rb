class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.25.3/qwen-code-darwin-arm64.tar.gz"
    sha256 "5aaf8bc885d516099eb4bd4caf702fb9b95cea327d0f74329c20611f4ed813d8"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.25.3/qwen-code-darwin-x64.tar.gz"
    sha256 "94b9ac1c7ada1182131c7ae6e98b60bcf235bb74233319546322f1aa5a031c5a"
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
