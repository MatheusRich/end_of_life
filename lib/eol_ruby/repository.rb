module EolRuby
  class Repository
    def self.fetch(language:, user:)
      response = GITHUB.search_repositories("user:#{user} language:#{language}", per_page: 100)
      warn "Incomplete results" if response.incomplete_results

      response.items.map do |repo|
        Repository.new(
          full_name: repo.full_name
        )
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

    def fetch_file(file_path)
      GITHUB.contents(full_name, path: file_path)
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
