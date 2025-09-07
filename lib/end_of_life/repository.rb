module EndOfLife
  class Repository
    class << self
      def search(options) = Search.new(options).result
      alias_method :fetch, :search
    end

    attr_reader :full_name, :url

    def initialize(full_name:, url:, github_client:)
      @full_name = full_name
      @url = url
      @github_client = github_client
      @product_releases = {}
    end

    def using_eol?(product, at: Date.today)
      min_release_of(product)&.eol?(at: at)
    end

    def min_release_of(product) = releases_for(product).min

    private

    def releases_for(product)
      @product_releases[product] ||= product.version_detector.detect_all(
        fetch_files(product.version_detector.relevant_files)
      )
    end

    def fetch_files(file_paths)
      Sync do
        file_paths
          .map { |file_path| Async { fetch_file(file_path) } }
          .filter_map { |task|
            file = task.wait
            next if file.nil?

            InMemoryFile.new(file.path, decode_file(file))
          }
      end
    end

    def fetch_file(file_path)
      @github_client.contents(full_name, path: file_path)
    rescue Octokit::NotFound
      nil
    end

    def decode_file(file)
      return file.content if file.encoding.nil?
      return Base64.decode64(file.content) if file.encoding == "base64"

      raise ArgumentError, "Unsupported encoding: #{file.encoding.inspect}"
    end
  end
end
