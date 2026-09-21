require "dry-monads"
require "faraday/retry"
require "json"
require "octokit"

# Sawyer chooses its JSON backend at run time from the gems it finds, although
# it depends on none of them, so an unrelated gem decides how the scan reads
# every GitHub response. `multi_json` before 1.21.2 is one such gem: it calls
# `JSON.parse` with two positional arguments, which `json` 3.x rejects, so a
# bad token reported `wrong number of arguments` instead of `401 - Bad
# credentials`. This chooses the backend instead. It also chooses `JSON.parse`
# over the `JSON.load` of Sawyer, which builds objects from a `json_class` key.
Sawyer::Agent.serializer = Sawyer::Serializer.new(JSON, :generate, :parse)

module EndOfLife
  module GitHub
    Error = Class.new(StandardError)

    # Octokit retries only the idempotent methods, and it waits no time between
    # the tries. The GraphQL fetch is a POST, so it never retried before. Every
    # request this client makes only reads, so a POST is safe to retry.
    RETRY_OPTIONS = {
      max: 3,
      interval: 0.5,
      backoff_factor: 2,
      interval_randomness: 0.5,
      methods: Faraday::Retry::Middleware::IDEMPOTENT_METHODS + [:post],
      exceptions: Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [Octokit::ServerError]
    }.freeze

    extend self
    include Dry::Monads[:result]

    def connect
      token = ENV["GITHUB_TOKEN"] or return Failure("Please set GITHUB_TOKEN environment variable")

      Success(yield(Octokit::Client.new(access_token: token, middleware: middleware)))
    rescue Error, Octokit::Error => e
      Failure(e.message)
    rescue => e
      Failure("Unexpected error: #{e}")
    end

    private

    def middleware
      Octokit::Default::MIDDLEWARE.dup.tap do |stack|
        stack.swap(Faraday::Retry::Middleware, Faraday::Retry::Middleware, RETRY_OPTIONS)
      end
    end
  end
end
