require "bundler"

module EndOfLife
  module VersionDetectors
    module Ruby
      extend VersionDetector

      detects_from ".ruby-version" do |file_content|
        string_version = Parsers::RubyVersion.parse(file_content)

        Product::Release.ruby(string_version)
      end

      detects_from "Gemfile.lock" do |file_content|
        gemfile_lock_version = Parsers::GemfileLock.parse(file_content).ruby_version or next

        Product::Release.ruby(gemfile_lock_version.delete_prefix("ruby "))
      end

      detects_from "Gemfile" do |file_content|
        gemfile = Parsers::Gemfile.parse(file_content)
        gemfile_version = gemfile&.ruby_version&.gem_version or next

        Product::Release.ruby(gemfile_version)
      end

      detects_from ".tool-versions" do |file_content|
        tool_versions = Parsers::ToolVersions.parse(file_content)
        ruby_version = tool_versions["ruby"] or next

        Product::Release.ruby(ruby_version)
      end
    end
  end
end
