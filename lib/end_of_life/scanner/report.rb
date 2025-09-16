require "stringio"

module EndOfLife
  module Scanner
    class Report < Data.define(:product, :repositories, :max_eol_date)
      include Helpers::Text
      include Helpers::Terminal

      def to_s
        report = StringIO.new
        report.puts

        if repositories.empty?
          report.puts "No repositories using EOL #{product}."
        else
          report.puts "Found #{pluralize(repositories.size, "repository", "repositories")} using EOL #{product} (<= #{product.latest_eol_release(at: max_eol_date)}):"
          report.puts end_of_life_table(repositories)
        end

        report.string
      end

      def failure? = repositories.any?

      private

      def end_of_life_table(repositories)
        headers = ["", "Repository", "#{product} version"]
        rows = repositories.map.with_index(1) do |repo, i|
          [i, repo.url, repo.min_release_of(product)]
        end

        table(headers, rows)
      end
    end
  end
end
