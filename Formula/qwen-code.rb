class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.23.2/qwen-code-darwin-arm64.tar.gz"
    sha256 "e6235b0630eba8c96d31f90d39e51fd944a8c4d7422240b62986ea5cb0712e2c"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.23.2/qwen-code-darwin-x64.tar.gz"
    sha256 "396fb75d7cdbca98352b8efe630b5af3d4caac4a903579afcc92aed5192316c0"
  end
  license "Apache-2.0"

  livecheck do
    url "https://github.com/QwenLM/qwen-code/releases/latest"
    strategy :github_latest
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
