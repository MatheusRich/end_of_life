module EndOfLife
  class Repository
    class << self
      include Dry::Monads[:result, :maybe]

      def fetch(options)
        github_client.bind do |github|
          github.auto_paginate = true
          options[:user] ||= github.user.login

          query = search_query_for(options)
          items = github.search_repositories(query, {sort: :updated}).items

          Success(
            items.filter_map do |repo|
              next if repo.archived && options[:skip_archived]

              Repository.new(
                full_name: repo.full_name,
                url: repo.html_url,
                github_client: github
              )
            end
          )
        rescue => e
          Failure("Unexpected error: #{e}")
        end
      end

      def github_client
        Maybe(ENV["GITHUB_TOKEN"])
          .fmap { |token| Octokit::Client.new(access_token: token) }
          .or { Failure("Please set GITHUB_TOKEN environment variable") }
      end

      def search_query_for(options)
        query = "language:ruby"

        query += if options[:repository]
          " repo:#{options[:repository]}"
        elsif options[:organizations]
          options[:organizations].map { |org| " org:#{org}" }.join
        else
          " user:#{options[:user]}"
        end

        if options[:visibility]
          query += " is:#{options[:visibility]}"
        end

        if options[:excludes]
          words_to_exclude = options[:excludes].map { |word| "NOT #{word} " }.join

          query += " #{words_to_exclude} in:name"
        end

        query
      end
    end

    attr :full_name, :url

    def initialize(full_name:, url:, github_client:)
      @full_name = full_name
      @url = url
      @github_client = github_client
    end

    def eol_ruby?(at: Date.today)
      ruby_version&.eol?(at: at)
    end

    def ruby_version
      return @ruby_version if defined?(@ruby_version)

      @ruby_version = ruby_versions.min
    end

    private

    def ruby_versions
      return @ruby_versions if defined?(@ruby_versions)

      @ruby_versions = begin
        ruby_version_files = [
          fetch_file(".ruby-version"),
          fetch_file("Gemfile"),
          fetch_file("Gemfile.lock"),
          fetch_file(".tool-versions")
        ].compact

        ruby_version_files.filter_map { |file| parse_version_file(file) }
      end
    end

    def fetch_file(file_path)
      @github_client.contents(full_name, path: file_path)
    rescue Octokit::NotFound
      nil
    end

    def parse_version_file(file)
      RubyVersion.from_file(file_name: file.name, content: decode_file(file))
    end

    def decode_file(file)
      return file.content if file.encoding.nil?
      return Base64.decode64(file.content) if file.encoding == "base64"

      raise ArgumentError, "Unsupported encoding: #{file.encoding.inspect}"
    end
  end
end
