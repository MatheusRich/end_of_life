require "dry-monads"
require "octokit"

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

          # GitHub doesn't have a way to get repos that contain specific files.
          # The language filter sort of works, but it might miss some repos that
          # use a language, but it's not the main one.
          #
          # We have to use the code search endpoint to find files matching the
          # product we're interested in and then extract the repositories from
          # the results.
          query = Query.new(options).to_s
          full_names = github.search_code(query).items.map { |item| item.repository.full_name }.uniq
          return Success([]) if full_names.empty?

          Success(fetcher_for(github).call(full_names))
        rescue => e
          Failure("Unexpected error: #{e}")
        end
      end

      private

      def fetcher_for(github)
        Fetcher.new(
          github_client: github,
          product: options[:product],
          skip_archived: options[:skip_archived]
        )
      end

      def github_client
        Maybe(ENV["GITHUB_TOKEN"])
          .fmap { |token| Octokit::Client.new(access_token: token) }
          .or { Failure("Please set GITHUB_TOKEN environment variable") }
      end
    end
  end
end
