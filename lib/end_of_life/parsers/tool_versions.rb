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

            tool, version, * = line.split

            next if version == "latest"

            [tool, Gem::Version.new(version)]
          }
          .to_h
      end
    end
  end
end
