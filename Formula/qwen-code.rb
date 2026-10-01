class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.24.7/qwen-code-darwin-arm64.tar.gz"
    sha256 "47a6d926e2f36da7260ad093c08110e9f8666e96b576dcbbc5abccd01a2a7fe1"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.24.7/qwen-code-darwin-x64.tar.gz"
    sha256 "1b6e7b4c34eba2b8de223f633bb6f5c1bc16f374ff510ea6b2df5006aa0d40e2"
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
