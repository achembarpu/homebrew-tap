cask "agent-orchestrator" do
  arch arm: "arm64", intel: "x64"

  version "0.13.2"
  sha256 arm:   "eb4c47f4552ae6da468e28f84b016c936d46c14e32c812df569a3fb0d8a98c16",
         intel: "17e3bb8eea92b56824650bcec8fc4a7f60ee1c6708357773d9e7c72678e00c7e"

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
