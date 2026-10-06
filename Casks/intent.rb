cask "intent" do
  arch arm: "arm64", intel: "x64"

  version "2.201.1"
  sha256 arm:   "02c88011f10fe9306834a875ba93d43af58ad19253e7907b16fcccb2e8346004",
         intel: "d0a1d3294b3a06b009729159f99a1241fb72a0075233d8cb04192599565c5d22"

  url "https://github.com/intent-hq/cloudlands-releases/releases/download/v#{version}/Intent-#{version}-#{arch}-mac.zip"
  name "Intent"
  desc "Desktop workspace for coordinating AI coding agents"
  homepage "https://intentapp.dev/"

  livecheck do
    url :url
    strategy :github_latest
  end

  auto_updates true
  depends_on macos: :ventura

  app "Intent.app"

  zap trash: [
    "~/Library/Application Support/intent-cloudlands",
    "~/Library/Preferences/app.cloudlands.intent.plist",
    "~/Library/Saved Application State/app.cloudlands.intent.savedState",
  ]

  caveats <<~EOS
    Intent requires a configured agent provider. It prompts to install Git and
    Node.js 22 or later if they are missing.

    Intent includes an automatic updater. To update through Homebrew, run
    `brew upgrade --cask intent`.

    Workspace, note, task, and agent data belongs to the intentd daemon and is
    stored in ~/Library/Application Support/intentd. It is preserved by zap so
    it can be reused by a standalone intentd installation.
  EOS
end
