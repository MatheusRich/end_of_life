module EolRuby
  class RubyVersion
    module Parser
      extend self

      def parse_file(file_name:, content:)
        if file_name == ".ruby-version"
          parse_ruby_version_file(content)
        elsif file_name == "Gemfile.lock"
          parse_gemfile_lock_file(content)
        elsif file_name == "Gemfile"
          parse_gemfile_file(content)
        else
          raise "Unsupported file #{file_name}"
        end
      end

      private

      def parse_ruby_version_file(file_content)
        string_version = file_content.strip.delete_prefix("ruby-")

        RubyVersion.new(string_version)
      end

      def parse_gemfile_lock_file(file_content)
        gemfile_lock_version = Bundler::LockfileParser.new(file_content).ruby_version
        return if gemfile_lock_version.nil?

        RubyVersion.new(gemfile_lock_version.delete_prefix("ruby "))
      end

      def parse_gemfile_file(file_content)
        return if file_content.empty?

        with_temp_gemfile(file_content) do |temp_gemfile|
          return nil if temp_gemfile.nil?

          gemfile_version = temp_gemfile.ruby_version&.gem_version
          return nil if gemfile_version.nil?

          RubyVersion.new(gemfile_version)
        end
      end

      def with_temp_gemfile(contents)
        Tempfile.create("tempGemfile") do |tempfile|
          tempfile.write(contents)
          tempfile.rewind
          gemfile = Bundler::Definition.build(tempfile.path, nil, {})

          yield(gemfile)
        rescue Bundler::BundlerError
          nil
        end
      end
    end
  end
end
