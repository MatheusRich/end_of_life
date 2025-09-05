module EndOfLife
  class Repository
    class Search
      include Dry::Monads[:result, :maybe]

      attr_reader :options

      def initialize(options)
        @options = options
      end

      def result
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

      private

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
  end
end
