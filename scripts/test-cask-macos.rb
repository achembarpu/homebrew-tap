# typed: strict
# frozen_string_literal: true

# Run with: brew ruby scripts/test-cask-macos.rb
require "cask/cask_loader"

root = File.expand_path("..", __dir__)
{
  "agent-orchestrator" => { "0.14.2" => nil, "0.14.9" => "13", "0.14.10" => "13" },
  "superset"           => { "1.38.0" => "12", "2.0.5" => "13", "2.0.10" => "13" },
}.each do |name, versions|
  original = File.read("#{root}/Casks/#{name}.rb")
  versions.each do |version, expected|
    source = original.sub(/^  version "[^"]+"$/, %Q(  version "#{version}"))
    cask = Cask::CaskLoader::FromContentLoader.new(source).load(config: nil)
    actual = cask.depends_on.macos.version&.to_s
    raise "#{name} #{version}: expected macOS #{expected.inspect}, got #{actual.inspect}" if actual != expected
  end
end

puts "PASS: cask macOS requirements across release versions"
