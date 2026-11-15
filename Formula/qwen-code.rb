class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.27.4/qwen-code-darwin-arm64.tar.gz"
    sha256 "2125616c6260401cbc60a478039232324e06cf5c32941f66140437c33171d6e9"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.27.4/qwen-code-darwin-x64.tar.gz"
    sha256 "fb6115bf2bef590daa4591a087c1816b3cc7facdc396c2a08517fa7de5571079"
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
