require "rubygems"
require_relative "ruby_version/parser"

module EndOfLife
  class RubyVersion
    include Comparable

    DB_PATH = File.join(__dir__, "../end_of_life.json")

    class << self
      def from_file(file_name:, content:, parser: Parser)
        parser.parse_file(file_name: file_name, content: content)
      end

      def eol_versions_at(date)
        all_versions.filter { |version| version.eol_date <= date }
      end

      def latest_eol(at: Date.today)
        eol_versions_at(at).max
      end

      private

      def all_versions
        @all_versions ||= File
          .read(DB_PATH)
          .then { |json| JSON.parse(json, symbolize_names: true) }
          .map { |version| new(version[:latest], eol_date: Date.parse(version[:eol])) }
      end
    end

    attr :version, :eol_date

    def initialize(version_string, eol_date: nil)
      @version = Gem::Version.new(version_string)
      @eol_date = eol_date

      freeze
    end

    def eol?(at: Date.today)
      self <= RubyVersion.latest_eol(at: at)
    end

    def <=>(other)
      @version <=> other.version
    end

    def to_s
      @version.to_s
    end
  end
end
