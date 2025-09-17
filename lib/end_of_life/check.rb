require "argument_parser"

module EndOfLife
  module Check
    include Helpers::Terminal
    include Helpers::Time
    extend self

    def run(releases, options)
      report_for releases.map { |release_string| build_row(release_string, options) }
    end

    private

    def build_row(release_string, options)
      product_release = Product::Release.parse!(release_string)
      cycle_release = product_release.latest_release_in_cycle or raise(
        ArgumentError,
        "Unknown product release: #{release_string}"
      )

      status = if cycle_release.supported?(at: options[:max_eol_date])
        "Supported"
      elsif cycle_release.supported?(at: Date.today)
        "Near EOL"
      else
        "EOL"
      end

      eol_date = if cycle_release.eol_date
        eol_days_away = relative_time_in_words(cycle_release.eol_date)
        "#{cycle_release.eol_date} (#{eol_days_away})"
      else
        "N/A"
      end

      [cycle_release.to_s, status, eol_date]
    end

    HEADERS = ["Product Release", "Status", "EOL Date"].freeze
    def report_for(rows)
      puts table(HEADERS, rows)
      exit 1 if rows.any? { |_, status, _| status != "Supported" }
    end
  end
end
