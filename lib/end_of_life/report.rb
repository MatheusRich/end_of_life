require "stringio"

module EndOfLife
  class Report < Data.define(:repositories, :max_eol_date)
    include TerminalHelper

    def to_s
      report = StringIO.new
      report.puts

      if repositories.empty?
        report.puts "No repositories using EOL Ruby."
      else
        word = (repositories.size == 1) ? "repository" : "repositories"
        report.puts "Found #{repositories.size} #{word} using EOL Ruby (<= #{RubyVersion.latest_eol(at: max_eol_date)}):"
        report.puts end_of_life_table(repositories)
      end

      report.string
    end

    def failure? = repositories.any?

    private

    def end_of_life_table(repositories)
      headers = ["", "Repository", "Ruby version"]
      rows = repositories.map.with_index(1) do |repo, i|
        [i, repo.url, repo.ruby_version]
      end

      table(headers, rows)
    end
  end
end
