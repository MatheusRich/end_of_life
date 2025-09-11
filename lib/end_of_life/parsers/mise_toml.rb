require "perfect_toml"

module EndOfLife
  module Parsers
    module MiseToml
      extend self

      def parse(file_content)
        PerfectTOML.parse(file_content)["tools"]
      rescue PerfectTOML::ParseError
        nil
      end
    end
  end
end
