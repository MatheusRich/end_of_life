# frozen_string_literal: true

require "json"
require "Date"
require "octokit"
require_relative "eol_ruby/version"

module EolRuby
  class CLI
    def exit_with(message, code: -1)
      puts message
      exit(code)
    end

    EOL_RUBY = File.read("lib/eol_ruby.json")
      .then { |json| JSON.parse(json, symbolize_names: true) }
      .filter { |version| Date.parse(version[:eol]) <= Date.today }
      .map { |version| Gem::Version.new(version[:latest]) }
      .max

    def initialize
      @client = Octokit::Client.new(access_token: ENV["GITHUB_TOKEN"])
      @client_user = @client.user
    rescue Octokit::Unauthorized
      exit_with "Please set GITHUB_TOKEN environment variable"
    rescue => e
      exit_with "Unexpected error: #{e}"
    end

    def call(argv)
      fetch_repos(language: "ruby").each { |repo|
        # this ideally would be filtered on Github, but I don't think it's possible
        ruby_version_files = [get_repo_file(repo.full_name, ".ruby-version")].compact
        next if ruby_version_files.empty?

        min_ruby_version = ruby_version_files.map { |file|
          parse_ruby_version_file(file)
        }.min

        if min_ruby_version <= EOL_RUBY
          puts "#{repo.full_name} has Ruby #{min_ruby_version} and Ruby EOL is #{EOL_RUBY}"
        end
      }
    end

    private

    def fetch_repos(language:, user: @client_user.login)
      response = @client.search_repositories("user:#{user} language:#{language}", per_page: 100)
      warn "Incomplete results" if response.incomplete_results

      response.items
    end

    def get_repo_file(repo_name, file_path)
      @client.contents(repo_name, path: file_path)
    rescue Octokit::NotFound
      nil
    end

    RubyVersion = Gem::Version
    def parse_ruby_version_file(file)
      raise "Unsupported encoding: #{file.enconding.inspect}" if !file.enconding.nil? && file.enconding != "base64"

      if file.name == ".ruby-version"
        string_version = Base64.decode64(file.content).strip.delete_prefix("ruby-")
        RubyVersion.new(string_version)
      else
        raise "Unsupported file #{file.name}"
      end
    rescue ArgumentError
      puts "Unable to parse #{file.name} at #{file.path}"
      RubyVersion.new("0.0.0")
    end
  end
end
