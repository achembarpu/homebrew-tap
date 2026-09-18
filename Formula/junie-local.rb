# typed: strict
# frozen_string_literal: true

# Vendored setup command for the optional local model of the junie cask.
# Wraps JetBrains' official local/install.sh verbatim at a pinned revision,
# exposed as `junie-local-setup`. See the caveats for upstream hardware gates.
class JunieLocal < Formula
  desc "Setup command for Junie's optional local model"
  homepage "https://github.com/jetbrains-junie/junie"
  url "https://raw.githubusercontent.com/jetbrains-junie/junie/45c9bc207d4341ff1728d510f629b962fcfa40cc/local/install.sh"
  version "2026.09.15"
  sha256 "414c957d720d36aeea5a40d7611cef3b6c4c007e307b68b0c4038d57c0380761"

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
