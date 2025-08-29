module EndOfLife
  class CLI
    include TerminalHelper

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
      when :help
        puts options[:parser]
      when :version
        puts "end_of_life v#{EndOfLife::VERSION}"
      when :print_error
        abort error_msg(options[:error])
      else
        Scanner.scan(options)
      end
    end
  end
end
