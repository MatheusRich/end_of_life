module EndOfLife
  class Repository
    class << self
      include Dry::Monads[:result, :maybe]

      def fetch(language:, user:, organizations:, repository:)
        github_client.bind do |github|
          user ||= github.user.login
          query = search_query_for(language: language, user: user, repository: repository, organizations: organizations)

          response = github.search_repositories(query, per_page: 100)
          warn "Incomplete results: we only search 100 repos at a time" if response.incomplete_results

          Success(
            response.items.map do |repo|
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

      def search_query_for(language:, user:, repository:, organizations:)
        query = "language:#{language}"
        query += if repository
          " repo:#{repository}"
        elsif organizations
          organizations.map { |org| " org:#{org}" }.join
        else
          " user:#{user}"
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
