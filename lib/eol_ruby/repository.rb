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
      return nil if ruby_version_files.empty?

      ruby_version_files.map { |file|
        parse_ruby_version_file(file)
      }.min
    end

    private

    def fetch_file(file_path)
      GITHUB.contents(full_name, path: file_path)
    rescue Octokit::NotFound
      nil
    end

    def parse_ruby_version_file(file)
      raise "Unsupported encoding: #{file.enconding.inspect}" if !file.enconding.nil? && file.enconding != "base64"

      if file.name == ".ruby-version"
        string_version = Base64.decode64(file.content).strip.delete_prefix("ruby-")
        RubyVersion.new(string_version)
      else
        raise "Unsupported file #{file.name}"
      end
    rescue ArgumentError
      puts "Unable to parse #{file.name} at #{file.path}"
      RubyVersion.new("0.0.0")
    end
  end
end
