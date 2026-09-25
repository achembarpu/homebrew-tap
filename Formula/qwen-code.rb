class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.24.5/qwen-code-darwin-arm64.tar.gz"
    sha256 "8911014f04df264003357eba2e628c41214f079edbae7e955712a655f0365819"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.24.5/qwen-code-darwin-x64.tar.gz"
    sha256 "b30476608f56a2d705452e3c06a00f325d83f58674988d59c9d11457ce880006"
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
