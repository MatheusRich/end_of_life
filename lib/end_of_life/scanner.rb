module EndOfLife
  module Scanner
    include Helpers::Terminal
    extend self

    def scan(options)
      fetch_repositories(options)
        .fmap { |repositories| filter_repositories_with_eol_products(repositories, **options.slice(:product, :max_eol_date)) }
        .fmap { |repositories| output_report(repositories, **options.slice(:product, :max_eol_date)) }
        .or { |error| abort "\n#{error_msg(error)}" }
    end

    private

    def fetch_repositories(options)
      with_loading_spinner("Searching repositories with #{options[:product].label}...") do |spinner|
        result = Repository.fetch(options)
        spinner.error if result.failure?

        result
      end
    end

    def filter_repositories_with_eol_products(repositories, product:, max_eol_date:)
      with_loading_spinner("Searching for EOL #{product} in your repositories...") do
        Sync do
          repositories
            .map { |repo| Async { [repo, repo.using_eol?(product, at: max_eol_date)] } }.map(&:wait)
            .filter_map { |repo, contains_eol| contains_eol ? repo : nil }
        end
      end
    end

    def output_report(repositories, product:, max_eol_date:)
      report = Report.new(product, repositories, max_eol_date)
      puts report

      exit(1) if report.failure?
    end
  end
end
