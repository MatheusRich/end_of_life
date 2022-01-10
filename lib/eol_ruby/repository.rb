module EolRuby
  class Repository
    class << self
      def fetch(language:, user: nil)
        user ||= github.user.login
        response = github.search_repositories("user:#{user} language:#{language}", per_page: 100)
        warn "Incomplete results" if response.incomplete_results

        response.items.map do |repo|
          Repository.new(full_name: repo.full_name)
        end
      end

      def github
        @github ||= github_client
      end

      private

      def github_client
        github_access_token = ENV.fetch("GITHUB_TOKEN") do
          EolRuby.exit_with "Please set GITHUB_TOKEN environment variable"
        end

        Octokit::Client.new(access_token: github_access_token)
      end
    end

    attr :full_name

    def initialize(full_name:)
      @full_name = full_name
    end

    def eol_ruby?
      !!ruby_version&.eol?
    end

    def ruby_version
      ruby_version_files = [fetch_file(".ruby-version")].compact
      return if ruby_version_files.empty?

      ruby_version_files.map { |file| parse_version_file(file) }.min
    end

    private

    def github
      self.class.github
    end

    def fetch_file(file_path)
      github.contents(full_name, path: file_path)
    rescue Octokit::NotFound
      nil
    end

    def parse_version_file(file)
      RubyVersion.from_file(file_name: file.name, content: decode_file(file))
    end

    def decode_file(file)
      return file if file.encoding.nil?
      return Base64.decode64(file.content) if file.encoding == "base64"

      raise "Unsupported encoding: #{file.encoding.inspect}"
    end
  end
end
