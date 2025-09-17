module EndOfLife
  module Scanner
    include Helpers::Terminal
    include Helpers::Text
    extend self

    def scan(product, options)
      fetch_repositories(product, options)
        .fmap { |repositories| filter_repositories_with_eol_products(repositories, product, options[:max_eol_date]) }
        .fmap { |repositories| output_report(repositories, product, options[:max_eol_date]) }
        .or { |error| abort "\n#{error_msg(error)}" }
    end

    private

    def fetch_repositories(product, options)
      with_loading_spinner("Searching repositories that might use #{product.label}...") do |spinner|
        result = Repository.search(options.merge(product:))
        spinner.error if result.failure?

        result
      end
    end

    def filter_repositories_with_eol_products(repositories, product, max_eol_date)
      return [] if repositories.empty?

      with_loading_spinner("Scanning #{pluralize(repositories.size, "repository", "repositories")} for EOL #{product.label}...") do
        Sync do
          repositories
            .map { |repo| Async { [repo, repo.using_eol?(product, at: max_eol_date)] } }.map(&:wait)
            .filter_map { |repo, contains_eol| contains_eol ? repo : nil }
        end
      end
    end

    def output_report(repositories, product, max_eol_date)
      report = Report.new(product, repositories, max_eol_date)
      puts report

      exit(1) if report.failure?
    end
  end
end
