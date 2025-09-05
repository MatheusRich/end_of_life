module EndOfLife
  class Product
    attr_reader :name
    def initialize(name) = @name = name.downcase

    def eol_releases_at(date)
      all_releases.filter { |release| release.eol_date <= date }
    end

    def latest_eol_release(at: Date.today)
      eol_releases_at(at).max
    end

    def label = name.capitalize
    def to_s = label

    private

    def all_releases
      @all_releases ||= API.fetch_product(name)
        .dig(:result, :releases)
        .map { |json| Release.new(name, json[:latest][:name], json[:eolFrom]) }
    end
  end
end
