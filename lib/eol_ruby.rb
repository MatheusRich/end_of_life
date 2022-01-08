# frozen_string_literal: true

require "json"
require "Date"
require "octokit"
require_relative "eol_ruby/repository"
require_relative "eol_ruby/ruby_version"
require_relative "eol_ruby/version"

module EolRuby
  GITHUB = begin
    Octokit::Client.new(access_token: ENV.fetch("GITHUB_TOKEN") { exit_with "Please set GITHUB_TOKEN environment variable" })
  rescue => e
    exit_with "Unexpected error: #{e}"
  end

  class CLI
    def call(argv)
      Repository
        .fetch(language: "ruby", user: GITHUB.user.login)
        .filter { |repo| repo.eol_ruby? }
        .then { |repos| diagnose_for(repos) }
    end

    def diagnose_for(repos)
      return if repos.empty?

      puts
      puts
      puts "Found #{repos.size} repository(ies) with Ruby EOL (i.e. <= #{RubyVersion::EOL}):"
      repos.each { puts [_1.full_name, _1.ruby_version].join(" | Ruby ") }
    end
  end

  def exit_with(message, code: -1)
    puts message
    exit(code)
  end
end
