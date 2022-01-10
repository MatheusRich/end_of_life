# frozen_string_literal: true

require "json"
require "octokit"
require_relative "eol_ruby/repository"
require_relative "eol_ruby/ruby_version"
require_relative "eol_ruby/version"

module EolRuby
  def self.exit_with(message, code: -1)
    puts(message)
    exit(code)
  end

  class CLI
    def call(argv)
      Repository
        .fetch(language: "ruby", user: nil)
        .filter { |repo| repo.eol_ruby? }
        .then { |repos| print_diagnose_for(repos) }
    rescue => e
      EolRuby.exit_with "Unexpected error: #{e}"
    end

    private

    def print_diagnose_for(repos)
      return if repos.empty?

      puts
      puts
      puts "Found #{repos.size} repository(ies) with Ruby EOL (<= #{RubyVersion::EOL}):"
      repos.each { puts [_1.full_name, _1.ruby_version].join(" | Ruby ") }
    end
  end
end
