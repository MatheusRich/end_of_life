require "dry-monads"
require "octokit"

module EndOfLife
  class Repository
    class << self
      include Dry::Monads[:result]

      def search(options) = with_client { |github| Search.new(github, options).result }

      def fetch(full_names, options) = with_client { |github| Fetcher.new(github, options).call(full_names) }

      private

      def with_client
        token = ENV["GITHUB_TOKEN"] or return Failure("Please set GITHUB_TOKEN environment variable")

        Success(yield(Octokit::Client.new(access_token: token)))
      rescue => e
        Failure("Unexpected error: #{e}")
      end
    end

    attr_reader :full_name, :url, :files

    def initialize(full_name:, url:, files: [])
      @full_name = full_name
      @url = url
      @files = files
      @product_releases = {}
    end

    def using_eol?(product, at: Date.today)
      min_release_of(product)&.eol?(at: at)
    end

    def min_release_of(product) = releases_for(product).min

    private

    def releases_for(product)
      @product_releases[product] ||= product.version_detector.detect_all(files)
    end
  end
end
