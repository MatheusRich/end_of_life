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
        string_version = file_content.strip.delete_prefix("ruby-")

        Product::Release.ruby(string_version)
      end

      def parse_gemfile_lock(file_content)
        with_silent_bundler do
          gemfile_lock_version = Bundler::LockfileParser.new(file_content).ruby_version
          return if gemfile_lock_version.nil?

          Product::Release.ruby(gemfile_lock_version.delete_prefix("ruby "))
        end
      end

      def parse_gemfile(file_content)
        with_temp_gemfile(file_content) do |temp_gemfile|
          gemfile_version = temp_gemfile.ruby_version&.gem_version
          return if gemfile_version.nil?

          Product::Release.ruby(gemfile_version)
        end
      end

      def parse_tool_versions(file_content)
        file_content
          .split("\n")
          .filter_map do |line|
            tool, version = line.strip.split

            tool == "ruby" && Product::Release.ruby(version)
          end
          .first
      end

      def with_silent_bundler
        previous_ui = Bundler.ui
        Bundler.ui = Bundler::UI::Silent.new

        yield
      ensure
        Bundler.ui = previous_ui
      end

      def with_temp_gemfile(contents)
        # Bundler requires a file to parse, so we need to create a temporary file
        Tempfile.create("tempGemfile") do |tempfile|
          tempfile.write(contents)
          tempfile.rewind
          gemfile = with_silent_bundler do
            # This is security problem, since it runs the code inside the file
            Bundler::Definition.build(tempfile.path, nil, {})
          end

          yield(gemfile)
        rescue Bundler::BundlerError
          nil
        end
      end
    end
  end
end
