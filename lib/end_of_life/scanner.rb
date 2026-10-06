module EndOfLife
  module Scanner
    include Helpers::Terminal
    include Helpers::Text
    extend self

    def scan(product, options)
      options = options.merge(product:)

      result = search_repositories(product, options)
        .on_success { |full_names| scan_repositories(full_names, product, options) }

      abort "\n#{error_msg(result.error)}" if result.failed?

      output_report(result.value, product, options[:max_eol_date])
    end

    private

    def search_repositories(product, options)
      with_loading_spinner("Searching repositories that might use #{product.label}...") do
        Repository.search(options)
      end
    end

    def scan_repositories(full_names, product, options)
      return Result::Success.new([]) if full_names.empty?

      with_loading_spinner("Scanning #{pluralize(full_names.size, "repository", "repositories")} for EOL #{product.label}...") do
        Repository.fetch(full_names, options).on_success { |repositories|
          Result::Success.new(repositories.filter { |repository| repository.using_eol?(product, at: options[:max_eol_date]) })
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
