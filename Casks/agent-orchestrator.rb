cask "agent-orchestrator" do
  arch arm: "arm64", intel: "x64"

  version "0.13.1"
  sha256 arm:   "4f52d44f3f2bc07455b1889af1743b7dddfceefe498f072d87aa26f0037c3d11",
         intel: "898c8252ebf2149f5038bd75486324b20f36ce41c39a47df5903aa11d7fa6140"

  url "https://github.com/Untrivial-ai/agent-orchestrator/releases/download/v#{version}/agent-orchestrator-darwin-#{arch}.zip"
  name "Agent Orchestrator"
  desc "Desktop workspace for orchestrating coding agents"
  homepage "https://github.com/Untrivial-ai/agent-orchestrator"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on :macos

  app "Agent Orchestrator.app"

  # The release ZIP ships AppleDouble (._) metadata files inside the bundle,
  # which break the Developer ID signature's seal. Clear quarantine and
  # re-sign locally so Gatekeeper accepts the installed app.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-cr", "{{appdir}}/Agent Orchestrator.app"]
    run "/usr/bin/codesign",
        args: ["--force", "--deep", "--sign", "-", "{{appdir}}/Agent Orchestrator.app"]
  end

  zap trash: "~/.ao"

  caveats <<~EOS
    Agent Orchestrator starts a local daemon and runs the coding agent CLIs
    that you configure separately.

    The production app enables remote product telemetry. See the upstream
    telemetry documentation for details.
  EOS
end
