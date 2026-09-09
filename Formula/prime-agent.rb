class PrimeAgent < Formula
  desc "Self-improving coding and research agent"
  homepage "https://github.com/PrimeIntellect-ai/prime-agent"
  url "https://github.com/PrimeIntellect-ai/prime-agent/releases/download/v0.9.4/prime-agent-0.9.4.tgz"
  sha256 "b8d752a53d11a8c9a7580e1fb5fc24f7ce74ccad979c7e6e6aa8880fc3ad90b0"
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
      koffi_arch = "darwin_x64"
      zeromq_arch = "x64"
    else
      koffi_arch = "darwin_arm64"
      zeromq_arch = "arm64"
    end

    [
      native_modules / "koffi/build/koffi/#{koffi_arch}",
      native_modules / "zeromq/build/darwin/#{zeromq_arch}",
    ].each do |obsolete_module|
      rm_r obsolete_module if obsolete_module.exist?
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
