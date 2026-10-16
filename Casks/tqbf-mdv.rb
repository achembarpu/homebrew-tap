cask "tqbf-mdv" do
  version "1.5.1"
  sha256 "c5d305be125f256ced5aed92d492741e6f3b94d249ba0e6da1545dc1477e95c2"

  url "https://github.com/tqbf/mdv/releases/download/v#{version}/mdv-#{version}-macos.zip"
  name "mdv"
  desc "Native Markdown viewer with history, bookmarks, and a TOC sidebar"
  homepage "https://github.com/tqbf/mdv"

  livecheck do
    url :url
    strategy :github_latest
  end

  depends_on arch: :arm64
  depends_on macos: :ventura

  app "mdv.app"

  uninstall quit:   "com.mdv.app",
            signal: ["TERM", "com.mdv.app"]

  zap script: {
        executable: "/bin/sh",
        args:       ["-c", <<~SH],
          link="/usr/local/bin/mdv"
          if [ -L "$link" ]; then
            target=$(/usr/bin/readlink "$link") || exit "$?"
            target=$(/usr/bin/ruby -e 'puts File.expand_path(ARGV.fetch(0), File.dirname(ARGV.fetch(1)))' "$target" "$link") || exit "$?"
            case "$target" in
              */mdv.app/Contents/Resources/mdv) /bin/rm -- "$link" ;;
            esac
          fi
        SH
        sudo:       true,
      },
      trash:  [
        "~/Library/Application Support/mdv",
        "~/Library/Caches/com.mdv.app",
        "~/Library/HTTPStorages/com.mdv.app",
        "~/Library/HTTPStorages/com.mdv.app.binarycookies",
        "~/Library/Logs/com.mdv.app",
        "~/Library/Preferences/com.mdv.app.plist",
        "~/Library/Saved Application State/com.mdv.app.savedState",
        "~/Library/WebKit/com.mdv.app",
      ]
end
