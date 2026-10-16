cask "happier" do
  arch arm: "aarch64", intel: "x86_64"

  version "0.2.17"
  sha256 arm:   "2a8611e44018f25e0c1e38e4370682d9cbbea311f5954fd784aabb73b9510d46",
         intel: "3283fa960084af9bc2457ee9954bea486c54c649d39aa55115071ceeb0c3fa80"

  # Adapted from happier-dev/happier's packaging/homebrew/Casks/happier.rb.
  url "https://github.com/happier-dev/happier/releases/download/ui-desktop-v#{version}/happier-ui-desktop-darwin-#{arch}-v#{version}.dmg"
  name "Happier"
  desc "Cross-device client for coding agents"
  homepage "https://happier.dev/"

  livecheck do
    url "https://github.com/happier-dev/happier/releases/download/ui-desktop-stable/latest.json"
    strategy :json do |json|
      json["version"]
    end
  end

  auto_updates true
  depends_on macos: :ventura

  app "Happier.app"

  uninstall quit:   "dev.happier.app",
            signal: ["TERM", "dev.happier.app"]

  # Run before trashing ~/.happier: managed Claude homes identify their
  # path-derived Keychain services, and CLI links may become dangling later.
  zap script: {
        executable: "/usr/bin/ruby",
        args:       ["-e", <<~'RUBY'],
          require "digest"
          require "etc"
          require "find"
          require "open3"

          def run!(*args)
            output, status = Open3.capture2e(*args)
            unless status.success?
              warn output
              exit(status.exitstatus || 1)
            end
            output
          end

          home = Dir.home
          root = File.join(home, ".happier")
          services = /\A(?:Happier|com\.happier\.cli\.daemon(?:\..+)?|happier-server(?:-preview|-dev)?)\z/
          run!("/bin/launchctl", "list").each_line do |line|
            label = line.split.last
            run!("/bin/launchctl", "remove", label) if label && services.match?(label)
          end

          # Check executable ownership separately from arguments: an unrelated
          # editor/search command can mention a managed path and daemon arguments.
          executables = {}
          run!("/bin/ps", "-x", "-o", "pid=,comm=").each_line do |line|
            pid, executable = line.strip.split(/\s+/, 2)
            executables[pid] = executable if pid && executable
          end
          # Detached managed daemons/relays also need stopping without a login agent.
          run!("/bin/ps", "-x", "-o", "pid=,command=").each_line do |line|
            pid, command = line.strip.split(/\s+/, 2)
            next unless pid && pid.to_i > 1 && command
            next if pid.to_i == Process.pid
            executable = executables[pid]
            next unless executable
            managed = executable.start_with?(root + "/")
            if !managed && %w[node bun happier-js-runtime].include?(File.basename(executable))
              # A system JS runtime may launch the managed packaged entrypoint.
              managed = command.start_with?(root + "/") ||
                        /\A\S+ (?:--no-warnings |--no-deprecation )*#{Regexp.escape(root)}\/[^\n]+\/(?:package-dist|dist)\/index\.mjs daemon start(?:-sync)?(?:\s|\z)/.match?(command)
            end
            next unless managed && command.include?(root + "/")
            next unless /\bdaemon start(?:-sync)?\b|\bhappier-server\b/.match?(command)

            begin
              Process.kill("TERM", pid.to_i)
            rescue Errno::ESRCH
              next
            end
            50.times do
              begin
                Process.kill(0, pid.to_i)
              rescue Errno::ESRCH
                break
              end
              sleep 0.1
            end
            begin
              Process.kill(0, pid.to_i)
              abort "Happier process #{pid} did not stop; refusing to remove its data"
            rescue Errno::ESRCH
              nil
            end
          end

          # Hash only proven managed homes; never delete the global Claude
          # login or another tool's path-derived credentials.
          if File.exist?(root)
            Find.find(root, ignore_error: false) do |path|
              next unless File.basename(path) == ".happier-claude-connected-service-home.json"

              service = "Claude Code-credentials-" + Digest::SHA256.hexdigest(File.dirname(path))[0, 8]
              loop do
                output, status = Open3.capture2e("/usr/bin/security", "delete-generic-password",
                                                "-s", service, "-a", Etc.getpwuid.name)
                break if status.exitstatus == 44
                next if status.success?

                warn output
                exit(status.exitstatus || 1)
              end
            end
          end

          # The shell installer may expose these shims in ~/.local/bin.
          %w[happier hprev hdev happier-server hstack].each do |name|
            link = File.join(home, ".local/bin", name)
            next unless File.symlink?(link)

            target = File.expand_path(File.readlink(link), File.dirname(link))
            File.unlink(link) if target.start_with?(root + "/")
          end

          # Remove only the default PATH entry bearing Desktop's own marker.
          %w[.zshrc .zprofile .bashrc .bash_profile .profile].each do |name|
            path = File.join(home, name)
            next unless File.exist?(path)

            content = File.read(path)
            marker = "# Added by Happier Desktop\n"
            export = 'export PATH="' + root + '/bin:$PATH"'
            cleaned = content.gsub(marker + export + "\n", "")
            File.write(path, cleaned) if cleaned != content
          end
        RUBY
        sudo:       false,
      },
      trash:  [
        "~/.happier",
        "~/Library/Application Support/dev.happier.app",
        "~/Library/Caches/dev.happier.app",
        "~/Library/HTTPStorages/dev.happier.app",
        "~/Library/HTTPStorages/dev.happier.app.binarycookies",
        "~/Library/LaunchAgents/com.happier.cli.daemon.*.plist",
        "~/Library/LaunchAgents/com.happier.cli.daemon.plist",
        "~/Library/LaunchAgents/happier-server-dev.plist",
        "~/Library/LaunchAgents/happier-server-preview.plist",
        "~/Library/LaunchAgents/happier-server.plist",
        "~/Library/LaunchAgents/Happier.plist",
        "~/Library/Logs/dev.happier.app",
        "~/Library/Preferences/dev.happier.app.plist",
        "~/Library/Saved Application State/dev.happier.app.savedState",
        "~/Library/WebKit/dev.happier.app",
      ]

  caveats <<~EOS
    First launch can download and set up the Happier CLI and background daemon.
    The app and managed CLI have their own signed update feeds.

    --zap removes the shared ~/.happier directory, including CLI installations,
    account keys, sessions, managed workspaces, local relay data, and models
    across release channels. Ordinary uninstall preserves this data.
    Custom HAPPIER_HOME_DIR locations and separately installed system relays
    require their own cleanup. macOS may require permission to remove protected
    files; a denied cleanup is an error, not evidence that the data is absent.
  EOS
end
