module EndOfLife
  module Parsers
    module GemfileLock
      extend Helpers::SilentBundler
      extend self

      def parse(file_content)
        silence_bundler do
          Bundler::LockfileParser.new(file_content)
        end
      rescue Bundler::BundlerError # outside a bundler project
        nil
      end
    end
  end
end
