module EndOfLife
  class CLI
    include Helpers::Terminal

    def call(argv)
      parse_options(argv)
        .then { |options| execute_command(options) }
    end

    private

    def parse_options(argv)
      Options.from(argv)
    end

    def execute_command(options)
      case options[:command]
      in :help
        puts options[:parser]
      in :version
        puts "end_of_life v#{EndOfLife::VERSION}"
      in :print_error
        abort error_msg(options[:error])
      in :scan
        Scanner.scan(options)
      end
    end
  end
end
