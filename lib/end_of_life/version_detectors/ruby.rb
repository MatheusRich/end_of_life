module EndOfLife
  module VersionDetectors
    module Ruby
      extend self

      RELEVANT_FILES = [
        ".ruby-version",
        "Gemfile.lock",
        "Gemfile",
        ".tool-versions"
      ].freeze
      def relevant_files = RELEVANT_FILES
    end
  end
end
