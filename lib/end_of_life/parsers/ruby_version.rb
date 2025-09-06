module EndOfLife
  module Parsers
    module RubyVersion
      extend self

      def parse(file_content)
        Gem::Version.new(file_content.strip.delete_prefix("ruby-"))
      end
    end
  end
end
