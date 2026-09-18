cask "agent-orchestrator" do
  arch arm: "arm64", intel: "x64"

  version "0.13.0"
  sha256 arm:   "53124dbed831082d15911e3b545f2c631851b9add618d3527954a709d9e44276",
         intel: "65cb27985989cb2f51472ea58a0178db1dbfdc53b6f65cedf75cfb55ff8a0776"

  url "https://github.com/Untrivial-ai/agent-orchestrator/releases/download/v#{version}/agent-orchestrator-darwin-#{arch}.zip"
  name "Agent Orchestrator"
  desc "Desktop workspace for orchestrating coding agents"
  homepage "https://github.com/Untrivial-ai/agent-orchestrator"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :big_sur

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
