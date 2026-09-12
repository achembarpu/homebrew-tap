class Yknotify < Formula
  desc "Notify when YubiKey needs touch on macOS"
  homepage "https://github.com/noperator/yknotify"
  url "https://github.com/noperator/yknotify/archive/0c773bdadedb137d02d95c79430fa5e0442c9950.tar.gz"
  version "0c773bdadedb137d02d95c79430fa5e0442c9950"
  sha256 "ac0a6726a7e05061e40dbc202ad642075f66f2350e273af80204b78e26aba585"
  license :cannot_represent

  livecheck do
    skip "Upstream has no release or version tags; source commit is pinned"
  end

  depends_on "go" => :build
  depends_on "jq"
  depends_on :macos

  def install
    system "go", "build", *std_go_args, "."

    libexec.mkpath
    (libexec/"yknotify-service").write <<~SH
      #!/bin/bash
      set -o pipefail

      last_notification=0
      "#{opt_bin}/yknotify" | while IFS= read -r event || [[ -n "$event" ]]; do
        event_type="$(printf '%s\\n' "$event" | jq -er 'select(type == "object") | .type | strings' 2>/dev/null)" || continue

        case "$event_type" in
          FIDO2|OpenPGP) ;;
          *) continue ;;
        esac

        now="$(/bin/date +%s)" || continue
        (( now - last_notification >= 2 )) || continue
        last_notification="$now"

        /usr/bin/osascript -e "display notification \\"$event_type\\" with title \\"yknotify\\" sound name \\"Submarine\\"" || true
      done
    SH
    chmod 0755, libexec/"yknotify-service"
  end

  service do
    run opt_libexec/"yknotify-service"
    keep_alive true
    run_at_load true
    process_type :background
    environment_variables PATH: std_service_path_env
  end

  def caveats
    <<~EOS
      yknotify watches macOS unified logs and writes detected touch requests as
      JSON lines to stdout. The notification service is opt-in and is not
      started during installation. Run `brew services start yknotify` to start
      the user LaunchAgent now and at login; run `brew services stop yknotify`
      to stop it and unregister it.
    EOS
  end

  test do
    assert_match "predicate", shell_output("#{bin}/yknotify -h 2>&1")
    assert_predicate libexec/"yknotify-service", :executable?
  end
end
