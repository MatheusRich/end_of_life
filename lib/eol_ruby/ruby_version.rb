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

    def self.from_file(file_name:, content:)
      if file_name == ".ruby-version"
        parse_ruby_version_file(content)
      else
        raise "Unsupported file #{file_name}"
      end
    end

    def self.parse_ruby_version_file(file_content)
      string_version = file_content.strip.delete_prefix("ruby-")

      RubyVersion.new(string_version)
    end

    def initialize(version_string)
      @version = Gem::Version.new(version_string)

      freeze
    end

    def eol?
      @version <= EOL
    end

    def_delegators :@version, :<=>, :to_s
  end
end
