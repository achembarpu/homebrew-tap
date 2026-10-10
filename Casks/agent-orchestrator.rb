cask "agent-orchestrator" do
  arch arm: "arm64", intel: "x64"

  version "0.13.6"
  sha256 arm:   "26f9d75c725130a9070155deaaa567ed4485aa7fb8ba18b4169fb7ebc0b9bcd0",
         intel: "ec646909cbf979f9770932262359d67f5929743e489564c0741bed4bc85b16a7"

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

  uninstall quit:   "dev.agent-orchestrator.desktop",
            signal: ["TERM", "dev.agent-orchestrator.desktop"]

  zap trash: [
    "~/.ao",
    "~/Library/Application Support/Agent Orchestrator",
    "~/Library/Caches/dev.agent-orchestrator.desktop",
    "~/Library/Caches/dev.agent-orchestrator.desktop.ShipIt",
    "~/Library/HTTPStorages/dev.agent-orchestrator.desktop",
    "~/Library/HTTPStorages/dev.agent-orchestrator.desktop.binarycookies",
    "~/Library/Logs/Agent Orchestrator",
    "~/Library/Logs/dev.agent-orchestrator.desktop",
    "~/Library/Preferences/dev.agent-orchestrator.desktop.plist",
    "~/Library/Saved Application State/dev.agent-orchestrator.desktop.savedState",
    "~/Library/WebKit/dev.agent-orchestrator.desktop",
  ]

  caveats <<~EOS
    Agent Orchestrator starts a local daemon and runs the coding agent CLIs
    that you configure separately.

    The production app enables remote product telemetry. See the upstream
    telemetry documentation for details.
  EOS
end
