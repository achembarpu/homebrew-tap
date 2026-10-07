class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.21.2/qwen-code-darwin-arm64.tar.gz"
    sha256 "73ed6e1fa43e393d26c3879449c31bd6d747e1e9cfe4b9c277a87b914fdfc81a"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.21.2/qwen-code-darwin-x64.tar.gz"
    sha256 "0e35d93dbe9d0b8f4079884e2172e140b52eff65582e260d9581d8713a5cc55a"
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
