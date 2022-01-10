# frozen_string_literal: true

require "json"
require "octokit"
require "warning"
require_relative "eol_ruby/repository"
require_relative "eol_ruby/ruby_version"
require_relative "eol_ruby/terminal_helper"
require_relative "eol_ruby/version"

at_exit do
  if defined?($error)
    puts
    puts $error
  end
end

module EolRuby
  extend TerminalHelper
  Warning.ignore(/Faraday::Connection#authorization/)

  class Exit < StandardError; end

  def self.listen_for_exit(on_exit: nil)
    yield
  rescue Exit => e
    $error = e.to_s
    on_exit&.call
    exit(-1)
  end

  class CLI
    include TerminalHelper

    def call(argv)
      EolRuby.listen_for_exit do
        fetch_repositories
          .then { |repositories| filter_repostories_with_eol_ruby(repositories) }
          .then { |repositories| print_diagnose_for(repositories) }
      rescue => e
        EolRuby.exit_with_error! "Unexpected failure: #{e}"
      end
    end

    private

    def fetch_repositories
      with_loading_spinner("Fetching repositories...") do |spinner|
        EolRuby.listen_for_exit(on_exit: -> { spinner.error }) do
          Repository.fetch(language: "ruby", user: nil)
        end
      end
    end

    def filter_repostories_with_eol_ruby(repositories)
      with_loading_spinner("Searching for EOL Ruby in repositories...") do
        repositories.filter { |repo| repo.eol_ruby? }
      end
    end

    def print_diagnose_for(repositories)
      puts

      if repositories.empty?
        puts "No repositories using EOL Ruby."
        return
      end

      puts eol_ruby_table(repositories)
    end

    def eol_ruby_table(repositories)
      headers = ["", "Repository", "Ruby version"]
      rows = repositories.map.with_index(1) do |repo, i|
        [i, repo.url, repo.ruby_version]
      end

      table(headers, rows)
    end
  end
end
