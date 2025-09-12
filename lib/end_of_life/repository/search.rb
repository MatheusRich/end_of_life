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
          repo_names = github.search_code(query).items.map { |item| item.repository.full_name }.uniq
          return Success([]) if repo_names.empty?

          repos_query = repo_names.map { |name| "repo:#{name}" }.join(" ")
          repos = github.search_repositories(repos_query, {sort: :updated}).items

          Success(
            repos.filter_map do |repo|
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
    end
  end
end
