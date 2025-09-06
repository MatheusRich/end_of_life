require "bundler"

module EndOfLife
  module VersionDetectors
    module Ruby
      extend self

      FILE_PARSERS = {
        ".ruby-version" => :parse_ruby_version,
        "Gemfile.lock" => :parse_gemfile_lock,
        "Gemfile" => :parse_gemfile,
        ".tool-versions" => :parse_tool_versions
      }.freeze

      def relevant_files = FILE_PARSERS.keys

      def detect_all(files)
        files.filter_map { |file| detect(file) }
      end

      def detect(file)
        parser = FILE_PARSERS[File.basename(file.path)] or return
        return if file.read.strip.empty?

        version = send(parser, file.read)

        return if version&.zero?

        version
      end

      private

      def parse_ruby_version(file_content)
        string_version = Parsers::RubyVersion.parse(file_content)

        Product::Release.ruby(string_version)
      end

      def parse_gemfile_lock(file_content)
        gemfile_lock_version = Parsers::GemfileLock.parse(file_content).ruby_version or return

        Product::Release.ruby(gemfile_lock_version.delete_prefix("ruby "))
      end

      def parse_gemfile(file_content)
        gemfile = Parsers::Gemfile.parse(file_content)
        gemfile_version = gemfile&.ruby_version&.gem_version or return

        Product::Release.ruby(gemfile_version)
      end

      def parse_tool_versions(file_content)
        tool_versions = Parsers::ToolVersions.parse(file_content)
        ruby_version = tool_versions["ruby"] or return

        Product::Release.ruby(ruby_version)
      end
    end
  end
end
