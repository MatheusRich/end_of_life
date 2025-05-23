require "bundler"
require "tempfile"

module EndOfLife
  class RubyVersion
    module Parser
      extend self

      def parse_file(file_name:, content:)
        return if content.strip.empty?

        version = if file_name == ".ruby-version"
          parse_ruby_version_file(content)
        elsif file_name == "Gemfile.lock"
          parse_gemfile_lock_file(content)
        elsif file_name == "Gemfile"
          parse_gemfile_file(content)
        elsif file_name == ".tool-versions"
          parse_tool_versions_file(content)
        else
          raise ArgumentError, "Unsupported file #{file_name}"
        end

        # Gem::Version is pretty forgiving and will accept empty strings
        # as valid versions. This is a catch-all to ensure we don't return
        # a version 0, which always takes precedence over any other version
        # when comparing.
        return if version&.zero?

        version
      end

      private

      def parse_ruby_version_file(file_content)
        string_version = file_content.strip.delete_prefix("ruby-")

        RubyVersion.new(string_version)
      end

      def parse_gemfile_lock_file(file_content)
        with_silent_bundler do
          gemfile_lock_version = Bundler::LockfileParser.new(file_content).ruby_version
          return if gemfile_lock_version.nil?

          RubyVersion.new(gemfile_lock_version.delete_prefix("ruby "))
        end
      end

      def parse_gemfile_file(file_content)
        with_temp_gemfile(file_content) do |temp_gemfile|
          gemfile_version = temp_gemfile.ruby_version&.gem_version
          return if gemfile_version.nil?

          RubyVersion.new(gemfile_version)
        end
      end

      def parse_tool_versions_file(file_content)
        file_content
          .split("\n")
          .filter_map do |line|
            tool, version = line.strip.split

            tool == "ruby" && RubyVersion.new(version)
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
