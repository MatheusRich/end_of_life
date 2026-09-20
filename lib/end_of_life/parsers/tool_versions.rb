module EndOfLife
  module Parsers
    module ToolVersions
      extend self

      def parse(file_content)
        file_content
          .lines
          .filter_map { |line|
            line = line.strip
            next if line.start_with?("#") || line.empty?

            line = line.split("#").first.strip # inline comments
            tool, version, * = line.split

            # Skip a version that is not a number, such as "lts" or "system".
            # The file still holds versions for the other tools.
            next unless version && Gem::Version.correct?(version)

            [tool, Gem::Version.new(version)]
          }
          .to_h
      end
    end
  end
end
