require "dry-monads"

module EndOfLife
  module Scanner
    include Dry::Monads[:result]
    include Helpers::Terminal
    include Helpers::Text
    extend self

    def scan(product, options)
      options = options.merge(product:)

      search_repositories(product, options)
        .bind { |full_names| scan_repositories(full_names, product, options) }
        .fmap { |repositories| output_report(repositories, product, options[:max_eol_date]) }
        .or { |error| abort "\n#{error_msg(error)}" }
    end

    private

    def search_repositories(product, options)
      with_loading_spinner("Searching repositories that might use #{product.label}...") do
        Repository.search(options)
      end
    end

    def scan_repositories(full_names, product, options)
      return Success([]) if full_names.empty?

      with_loading_spinner("Scanning #{pluralize(full_names.size, "repository", "repositories")} for EOL #{product.label}...") do
        Repository.fetch(full_names, options).fmap { |repositories|
          repositories.filter { |repository| repository.using_eol?(product, at: options[:max_eol_date]) }
        }
      end
    end

    def output_report(repositories, product, max_eol_date)
      report = Report.new(product, repositories, max_eol_date)
      puts report

      exit(1) if report.failure?
    end
  end
end
