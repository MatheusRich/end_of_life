module EndOfLife
  class CLI
    include TerminalHelper

    def call(argv)
      parse_options(argv)
        .then { |options| execute_command(options) }
    end

    private

    def execute_command(options)
      case options[:command]
      when :help
        puts options[:parser]
      when :version
        puts "end_of_life v#{EndOfLife::VERSION}"
      when :print_error
        abort error_msg(options[:error])
      else
        check_eol_ruby_on_repositories(options)
      end
    end

    def check_eol_ruby_on_repositories(options)
      fetch_repositories(options)
        .fmap { |repositories| filter_repositories_with_end_of_life(repositories, max_eol_date: options[:max_eol_date]) }
        .fmap { |repositories| print_diagnose_for(repositories, max_eol_date: options[:max_eol_date]) }
        .or { |error| abort "\n#{error_msg(error)}" }
    end

    def parse_options(argv)
      Options.from(argv)
    end

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

    def print_diagnose_for(repositories, max_eol_date:)
      puts

      if repositories.empty?
        puts "No repositories using EOL Ruby."
        return
      end

      word = (repositories.size == 1) ? "repository" : "repositories"
      puts "Found #{repositories.size} #{word} using EOL Ruby (<= #{RubyVersion.latest_eol(at: max_eol_date)}):"
      puts end_of_life_table(repositories)
      exit(-1)
    end

    def end_of_life_table(repositories)
      headers = ["", "Repository", "Ruby version"]
      rows = repositories.map.with_index(1) do |repo, i|
        [i, repo.url, repo.ruby_version]
      end

      table(headers, rows)
    end
  end
end
