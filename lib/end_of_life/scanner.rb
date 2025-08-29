module EndOfLife
  module Scanner
    include TerminalHelper
    extend self

    def scan(options)
      fetch_repositories(options)
        .fmap { |repositories| filter_repositories_with_end_of_life(repositories, max_eol_date: options[:max_eol_date]) }
        .fmap { |repositories| output_report(repositories, max_eol_date: options[:max_eol_date]) }
        .or { |error| abort "\n#{error_msg(error)}" }
    end

    private

    def fetch_repositories(options)
      with_loading_spinner("Fetching repositories...") do |spinner|
        result = Repository.fetch(options)

        spinner.error if result.failure?

        result
      end
    end

    def filter_repositories_with_end_of_life(repositories, max_eol_date:)
      with_loading_spinner("Searching for EOL Ruby in repositories...") do
        Sync do
          repositories
            .tap { |repos| repos.map { |repo| Async { repo.ruby_version } }.map(&:wait) }
            .filter { |repo| repo.eol_ruby?(at: max_eol_date) }
        end
      end
    end

    def output_report(repositories, max_eol_date:)
      report = Report.new(repositories, max_eol_date)
      puts report

      exit(1) if report.failure?
    end
  end
end
