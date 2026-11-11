class Qm < Formula
  desc "Deployment CLI for portable QM deployments"
  homepage "https://github.com/yc-software/qm/tree/main/cli#readme"
  url "https://registry.npmjs.org/@yc-software/qm/-/qm-0.1.17.tgz"
  sha256 "e387d48ec947f400febdfa20519671a51e709de0762aab94bc976cec23cb6d49"
  license "MIT"

  livecheck do
    url :stable
    strategy :npm
  end

  depends_on "node@24"

  def install
    system "npm", "install", *std_npm_args
    bin.install_symlink libexec / "bin/qm"
  end

  def caveats
    <<~EOS
      QM is a deployment control-plane CLI, not the QM runtime. Depending on
      the target, deployments require Docker Buildx, Flyctl, the AWS CLI, Git,
      and Terraform to be installed and authenticated separately.

      QM stores deployment configuration and state in each deployment
      directory. Formula uninstallation does not remove those files.

      Updates are managed by `brew upgrade qm`.
    EOS
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/qm --version").chomp
  end
end
