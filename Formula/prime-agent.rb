class PrimeAgent < Formula
  desc "Self-improving coding and research agent"
  homepage "https://github.com/PrimeIntellect-ai/prime-agent"
  url "https://github.com/PrimeIntellect-ai/prime-agent/releases/download/v0.9.7/prime-agent-0.9.7.tgz"
  sha256 "d696f2636cd7780d2d67296142bc1d13d72960c8be4e5cfae0bbba82f9d8707d"
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

    # npm installs only host-compatible optional native artifacts, so these
    # opposite-architecture directories may not exist.
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
