class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.24.2/qwen-code-darwin-arm64.tar.gz"
    sha256 "c4944a86fcb6e4ac2fb518041a339a3f315f1646732b335eeb1b90e556c87294"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.24.2/qwen-code-darwin-x64.tar.gz"
    sha256 "48c1c709d582aad1b5645b9d81930edadab3e744d0ed51801cdd8ae7f8d946ac"
  end
  license "Apache-2.0"

  livecheck do
    url "https://github.com/QwenLM/qwen-code/releases"
    regex(%r{/QwenLM/qwen-code/releases/tag/v(\d+(?:\.\d+)+)}i)
    strategy :page_match
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
