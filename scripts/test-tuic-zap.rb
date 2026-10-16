# typed: strict
# frozen_string_literal: true

# Verifies removal of app-signed CLI copies and ownership-checked links.
module TuicZapFixtures
  def self.verify(script, temporary, check)
    link = "#{temporary}/tuic"
    codesign = "#{temporary}/tuic-codesign"
    File.write(codesign, <<~SH)
      #!/bin/sh
      [ -z "$ZAP_TEST_ERROR" ] || exit "$ZAP_TEST_ERROR"
      for path; do :; done
      [ "$(cat "$path")" = 'app-owned signed copy' ]
    SH
    File.chmod(0755, codesign)
    source = script.fetch(:args).fetch(1).sub(/^link=.*$/, "link=\"#{link}\"")
                   .sub("/usr/bin/codesign", codesign)
    execute = ->(env = {}) { Open3.capture2e(env, "/bin/sh", "-c", source) }
    ["app-owned signed copy", "unrelated command"].each do |content|
      File.write(link, content)
      output, status = execute.call
      check.call(status.success? && File.exist?(link) == (content == "unrelated command"),
                 "tuicommander: copied CLI ownership failed: #{output}")
      FileUtils.rm_f(link)
    end
    targets = ["TUICommander.app/Contents/MacOS/tuic", "Other.app/Contents/MacOS/tuic",
               "TUICommander.app/Contents/MacOS/../../../Other.app/Contents/MacOS/tuic"]
    targets.each do |target|
      File.symlink("#{temporary}/#{target}", link)
      output, status = execute.call
      check.call(status.success? && File.symlink?(link) == target.include?("Other"),
                 "tuicommander: symlink ownership failed: #{output}")
      File.unlink(link) if File.symlink?(link)
    end
    output, status = execute.call
    check.call(status.success?, "tuicommander: absent CLI should succeed: #{output}")
    File.write(link, "app-owned signed copy")
    output, status = execute.call("ZAP_TEST_ERROR" => "50")
    check.call(status.exitstatus == 50 && File.exist?(link), "tuicommander: codesign error was swallowed: #{output}")
    failing_rm = "#{temporary}/tuic-failing-rm"
    File.write(failing_rm, "#!/bin/sh\nexit 55\n")
    File.chmod(0755, failing_rm)
    output, status = Open3.capture2e("/bin/sh", "-c", source.gsub("/bin/rm", failing_rm))
    check.call(status.exitstatus == 55 && File.exist?(link),
               "tuicommander: CLI removal error was swallowed: #{output}")
  end
end
