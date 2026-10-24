# typed: strict
# frozen_string_literal: true

# Vendored setup command for the optional local model of the junie cask.
# Wraps JetBrains' official local/install.sh verbatim at a pinned revision,
# exposed as `junie-local-setup`. See the caveats for upstream hardware gates.
class JunieLocal < Formula
  desc "Setup command for Junie's optional local model"
  homepage "https://github.com/jetbrains-junie/junie"
  url "https://raw.githubusercontent.com/jetbrains-junie/junie/d66ff663b984ee9b969e7b18bbef77968cc1dbb9/local/install.sh"
  version "2026.10.23"
  sha256 "9ce1cb55639c3b535e25b742357658f1b2f1137e350f5da88199d9ee949bbd3e"

  livecheck do
    skip "The script is intentionally pinned to an upstream commit"
  end

  depends_on arch: :arm64
  depends_on macos: :tahoe

  def install
    bin.install "install.sh" => "junie-local-setup"
  end

  def caveats
    <<~EOS
      The script is vendored verbatim from JetBrains' junie repo at a pinned
      revision; bumps here are deliberate re-pins, never live fetches.

      Upstream hard-gates the install: Apple M5 or newer, >= 40 GB RAM
      (60 GB recommended), macOS 26+. On first run it downloads several GB
      of engine and Qwen weights into ~/.local/share/junie-local and writes
      model config under ~/.junie — both outside brew management by design.
      Remove those directories manually if you later uninstall this formula.
    EOS
  end

  test do
    assert_path_exists bin/"junie-local-setup"
    system "#{bin}/junie-local-setup", "--help"
  end
end
