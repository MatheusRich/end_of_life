module EndOfLife
  module Schedule
    include Helpers::Terminal
    include Helpers::Time
    extend self

    def for(product_name)
      product = Product.find(product_name)
      rows = product.all_releases.sort.reverse.map { |release| build_row(release) }
      puts table(HEADERS, rows)
    end

    private

    HEADERS = ["Product Release", "Status", "EOL Date"].freeze

    def build_row(release)
      status = release.supported? ? "Supported" : "EOL"

      eol_date = if release.eol_date
        "#{release.eol_date} (#{relative_time_in_words(release.eol_date)})"
      else
        "N/A"
      end

      [release.to_s, status, eol_date]
    end
  end
end
