class PrimeAgent < Formula
  desc "Self-improving coding and research agent"
  homepage "https://github.com/PrimeIntellect-ai/prime-agent"
  url "https://github.com/PrimeIntellect-ai/prime-agent/releases/download/v0.9.2/prime-agent-0.9.2.tgz"
  version "0.9.2"
  sha256 "d649b9f0258c77de7d02aba33d786925ce41a36b601e8e24eef0f00bdc2f1f49"
  license "MIT"

  livecheck do
    url "https://github.com/PrimeIntellect-ai/prime-agent/releases/latest"
    strategy :github_latest
  end

  depends_on "node@22"

  def install
    system "npm", "install", *std_npm_args

    native_modules = libexec / "lib/node_modules/prime-agent/node_modules"
    if Hardware::CPU.arm?
      rm_r native_modules / "koffi/build/koffi/darwin_x64"
      rm_r native_modules / "zeromq/build/darwin/x64"
    else
      rm_r native_modules / "koffi/build/koffi/darwin_arm64"
      rm_r native_modules / "zeromq/build/darwin/arm64"
    end

    bin.install_symlink libexec / "bin/prime-agent"
  end

  def caveats
    <<~EOS
      Prime Agent stores global configuration, authentication, telemetry, logs,
      sessions, and managed tools under ~/.prime/agent.

      Formula uninstallation does not remove user data. To remove the global
      Prime Agent data manually, run:

        rm -rf ~/.prime/agent

      Project-local data under .prime/agent is not managed by Homebrew.

      Updates are managed by `brew upgrade prime-agent`. The IPython runtime
      and optional fd/rg tools are prepared lazily by Prime Agent as needed.
    EOS
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/prime-agent --version").chomp
  end
end
