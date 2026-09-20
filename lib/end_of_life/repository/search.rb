module EndOfLife
  class Repository
    class Search
      attr_reader :github, :options

      def initialize(github, options)
        @github = github
        @options = options
      end

      # GitHub doesn't have a way to get repos that contain specific files.
      # The language filter sort of works, but it might miss some repos that
      # use a language, but it's not the main one.
      #
      # We have to use the code search endpoint to find files matching the
      # product we're interested in and then extract the repositories from
      # the results.
      def result
        github.auto_paginate = true
        options[:user] ||= github.user.login

        github.search_code(Query.new(options).to_s).items.map { |item| item.repository.full_name }.uniq
      end
    end
  end
end
