module EndOfLife
  module Parsers
    module Gemfile
      extend Helpers::SilentBundler
      extend self

      def parse(file_content)
        with_temp_gemfile(file_content) do |gemfile|
          silence_bundler do
            # This is security problem, since it runs the code inside the file
            Bundler::Definition.build(gemfile.path, nil, {})
          end
        end
      end

      private

      def with_temp_gemfile(contents)
        # Bundler requires a file to parse, so we need to create a temporary file
        Tempfile.create("tempGemfile") do |tempfile|
          tempfile.write(contents)
          tempfile.rewind

          yield(tempfile)
        rescue Bundler::BundlerError
          nil # NOTE: maybe a Null object would be cleaner
        end
      end
    end
  end
end
