module EndOfLife
  class Repository
    class Search
      Query = Data.define(:options) do
        def to_s
          query = "language:ruby"

          query += if options[:repository]
            " repo:#{options[:repository]}"
          elsif options[:organizations]
            options[:organizations].map { |org| " org:#{org}" }.join
          else
            " user:#{options[:user]}"
          end

          if options[:visibility]
            query += " is:#{options[:visibility]}"
          end

          if options[:excludes]
            words_to_exclude = options[:excludes].map { |word| "NOT #{word} " }.join

            query += " #{words_to_exclude} in:name"
          end

          query
        end
      end
    end
  end
end
