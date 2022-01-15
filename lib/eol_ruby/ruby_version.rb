require "bundler"
require "tempfile"
require_relative "ruby_version/parser"

module EolRuby
  class RubyVersion
    include Comparable

    EOL = File.read("lib/eol_ruby.json")
      .then { |json| JSON.parse(json, symbolize_names: true) }
      .filter { |version| Date.parse(version[:eol]) <= Date.today }
      .map { |version| Gem::Version.new(version[:latest]) }
      .max

    def self.from_file(file_name:, content:)
      Parser.parse_file(file_name: file_name, content: content)
    end

    def self.parse_ruby_version_file(file_content)
      string_version = file_content.strip.delete_prefix("ruby-")

      RubyVersion.new(string_version)
    end

    def self.parse_gemfile_lock_file(file_content)
      gemfile_lock_version = Bundler::LockfileParser.new(file_content).ruby_version
      return if gemfile_lock_version.nil?

      RubyVersion.new(gemfile_lock_version.delete_prefix("ruby "))
    end

    def self.parse_gemfile_file(file_content)
      return if file_content.empty?

      with_temp_gemfile(file_content) do |temp_gemfile|
        return nil if temp_gemfile.nil?

        gemfile_version = temp_gemfile.ruby_version&.gem_version
        return nil if gemfile_version.nil?

        RubyVersion.new(gemfile_version)
      end
    end

    def self.with_temp_gemfile(contents)
      Tempfile.create("tempGemfile") do |tempfile|
        tempfile.write(contents)
        tempfile.rewind
        gemfile = Bundler::Definition.build(tempfile.path, nil, {})

        yield(gemfile)
      rescue Bundler::BundlerError
        nil
      end
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
