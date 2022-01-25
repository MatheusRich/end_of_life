# frozen_string_literal: true

require "json"
require "octokit"
require "optparse"
require_relative "end_of_life/repository"
require_relative "end_of_life/ruby_version"
require_relative "end_of_life/terminal_helper"
require_relative "end_of_life/version"

module EndOfLife
  extend TerminalHelper

  class CLI
    include TerminalHelper

    def call(argv)
      parse_options(argv)
        .then { |options| execute_command(options) }
    end

    private

    def execute_command(options)
      case options[:command]
      when :help
        puts options[:parser]
      when :version
        puts "end_of_life v#{EndOfLife::VERSION}"
      when :print_error
        puts error_msg(options[:error])
        exit(-1)
      else
        check_eol_ruby_on_repositories(options)
      end
    end

    def check_eol_ruby_on_repositories(options)
      fetch_repositories(user: options[:user])
        .fmap { |repositories| filter_repositories_with_end_of_life(repositories) }
        .fmap { |repositories| print_diagnose_for(repositories) }
        .or { |error| puts "\n#{error_msg(error)}" }
    end

    def parse_options(argv)
      options = {}

      OptionParser.new do |opts|
        options[:parser] = opts

        opts.banner = "Usage: end_of_life [options]"

        opts.on("-u NAME", "--user=NAME", "Sets the user used on the repository search") do |user|
          options[:user] = user
        end

        opts.on("-v", "--version", "Displays end_of_life version") do
          options[:command] = :version
        end

        opts.on("-h", "--help", "Displays this help") do
          options[:command] = :help
        end
      end.parse!(argv)

      options
    rescue OptionParser::ParseError => e
      {command: :print_error, error: e}
    end

    def fetch_repositories(user:)
      with_loading_spinner("Fetching repositories...") do |spinner|
        result = Repository.fetch(language: "ruby", user: user)

        spinner.error if result.failure?

        result
      end
    end

    def filter_repositories_with_end_of_life(repositories)
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
