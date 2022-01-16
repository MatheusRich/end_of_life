# frozen_string_literal: true

require "json"
require "octokit"
require "warning"
require_relative "end_of_life/repository"
require_relative "end_of_life/ruby_version"
require_relative "end_of_life/terminal_helper"
require_relative "end_of_life/version"

module EndOfLife
  extend TerminalHelper

  Warning.ignore(/Faraday::Connection#authorization/)

  class CLI
    include TerminalHelper

    def call(argv)
      fetch_repositories
        .fmap { |repositories| filter_repositories_with_end_of_life(repositories) }
        .fmap { |repositories| print_diagnose_for(repositories) }
        .or { |error| puts "\n#{error_msg(error)}" }
    end

    private

    def fetch_repositories
      with_loading_spinner("Fetching repositories...") do |spinner|
        result = Repository.fetch(language: "ruby")

        spinner.error if result.failure?

        result
      end
    end

    def filter_repositories_with_end_of_life(repositories)
      with_loading_spinner("Searching for EOL Ruby in repositories...") do
        repositories.filter { |repo| repo.end_of_life? }
      end
    end

    def print_diagnose_for(repositories)
      puts

      if repositories.empty?
        puts "No repositories using EOL Ruby."
        return
      end

      puts "Found #{repositories.size} repositories using EOL Ruby (<= #{RubyVersion::EOL}):"
      puts end_of_life_table(repositories)
    end

    def end_of_life_table(repositories)
      headers = ["", "Repository", "Ruby version"]
      rows = repositories.map.with_index(1) do |repo, i|
        [i, repo.url, repo.ruby_version]
      end

      table(headers, rows)
    end
  end
end
