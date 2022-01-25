require 'rubygems'
require_relative "ruby_version/parser"

module EndOfLife
  class RubyVersion
    include Comparable

    DB_PATH = File.join(__dir__, "../end_of_life.json")

    EOL = File.read(DB_PATH)
      .then { |json| JSON.parse(json, symbolize_names: true) }
      .filter { |version| Date.parse(version[:eol]) <= Date.today }
      .map { |version| Gem::Version.new(version[:latest]) }
      .max

    def self.from_file(file_name:, content:, parser: Parser)
      parser.parse_file(file_name: file_name, content: content)
    end

    attr :version

    def initialize(version_string)
      @version = Gem::Version.new(version_string)

      freeze
    end

    def eol?
      @version <= EOL
    end

    def <=>(other)
      @version <=> other.version
    end

    def to_s
      @version.to_s
    end
  end
end
