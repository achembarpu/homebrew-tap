class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.24.4/qwen-code-darwin-arm64.tar.gz"
    sha256 "333c1beb134569eeb56cb8a6b7ca28f85b49ef5a5886f74455f37f943f55c596"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.24.4/qwen-code-darwin-x64.tar.gz"
    sha256 "f870e3586871e78e0ac2fd3474c51bfb9dca2d282fefef5f3f681e8a9d0dc9f5"
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
