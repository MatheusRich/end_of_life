module EndOfLife
  class Product
    def self.find(name) = EndOfLife.find_product(name)

    attr_reader :name, :version_detector, :label

    def initialize(name, version_detector, label = nil)
      @name = name.to_s.downcase
      @version_detector = version_detector
      @label = label || @name.capitalize
    end

    def eol_releases_at(date)
      all_releases.filter { |release| release.eol_date.nil? || release.eol_date <= date }
    end

    def latest_eol_release(at: Date.today)
      eol_releases_at(at).max
    end

    def all_releases
      @all_releases ||= API.fetch_product(name)
        .dig(:result, :releases)
        .map { |json| Release.new(name, json[:latest][:name], json[:eolFrom]) }
    end

    def search_query
      version_detector.relevant_files.map { |f| %(filename:"#{f}") }.join(" ")
    end

    def to_s = label
  end
end
