class QwenCode < Formula
  desc "Open-source AI coding agent for the terminal"
  homepage "https://qwenlm.github.io/qwen-code-docs/en/users/overview"
  if Hardware::CPU.arm?
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.25.1/qwen-code-darwin-arm64.tar.gz"
    sha256 "09c3968cb9fce416765ad4fb5463c01add5798d82b3604b99b8a11aebf304807"
  else
    url "https://github.com/QwenLM/qwen-code/releases/download/v0.25.1/qwen-code-darwin-x64.tar.gz"
    sha256 "ad615aca6bec3fd0d831404858ed46c9deb8f79f11b8b4e4feeefb8c9da6f4de"
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
