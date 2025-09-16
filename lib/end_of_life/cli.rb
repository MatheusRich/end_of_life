module EndOfLife
  class CLI
    def call(argv)
      parse_options(argv)
        .then { |options| execute_command(argv, options) }
    end

    private

    def parse_options(argv)
      Options.from(argv)
    end

    def execute_command(argv, options)
      case options[:command]
      in :help
        puts options[:parser]
      in :version
        puts "end_of_life v#{EndOfLife::VERSION}"
      in :abort
        abort options[:error]
      in :scan
        Scanner.scan(options)
      in :check
        Check.run(argv, options)
      end
    end
  end
end
