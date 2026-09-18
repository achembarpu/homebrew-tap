class DeepseekHarness < Formula
  desc "Plugin-based AI agent harness"
  homepage "https://github.com/deepseek-ai/deepseek-harness"
  url "https://registry.npmjs.org/@deepseek-ai/dsh/-/dsh-0.1.5-rc.2.tgz"
  sha256 "f4c54839d69e82bf1c3a5a41a910c3ce1405cd9e9d97d753c0c04f406c7d7480"
  license "MIT"

  livecheck do
    url :stable
    strategy :npm
  end

  depends_on "node"
  depends_on "pnpm"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec / "bin/dsh"
  end

  def caveats
    <<~EOS
      DeepSeek Harness stores profiles, sessions, credentials, configuration,
      and user-installed plugins under ~/.dsh.

      Formula uninstallation does not remove that user data. Remove it
      manually if desired:

        rm -rf ~/.dsh

      DeepSeek Harness can execute model-generated commands, load third-party
      plugins, and access files, processes, credentials, and the network made
      available to it. Upstream states that its sandbox, approval prompts, and
      permission controls do not guarantee isolation. Review the safety notice
      and use a disposable environment for untrusted workloads:

        https://github.com/deepseek-ai/deepseek-harness/blob/dsh-v0.1.2-rc.1/SAFETY.md

      The formula keeps the Node runtime dependencies inside the Homebrew keg.
      Updates are managed by `brew upgrade deepseek-harness`.
    EOS
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/dsh --version").chomp
  end
end
