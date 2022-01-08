require "forwardable"

module EolRuby
  class RubyVersion
    extend Forwardable
    include Comparable

    EOL = File.read("lib/eol_ruby.json")
      .then { |json| JSON.parse(json, symbolize_names: true) }
      .filter { |version| Date.parse(version[:eol]) <= Date.today }
      .map { |version| Gem::Version.new(version[:latest]) }
      .max

    def initialize(version_string)
      @version = Gem::Version.new(version_string)
    end

    def eol?
      @version <= EOL
    end

    def_delegators :@version, :<=>, :to_s
  end
end
