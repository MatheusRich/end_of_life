module EndOfLife
  class Repository
    class << self
      def search(options) = Search.new(options).result
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
