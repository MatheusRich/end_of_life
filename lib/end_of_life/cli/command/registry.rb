require "optparse"

module EndOfLife
  class CLI
    module Command::Registry
      Command = Data.define(:name, :summary, :parser, :action) do
        include Helpers::Terminal

        def run(argv)
          action.call(argv, parser)
        rescue OptionParser::ParseError, ArgumentParser::Error => e
          abort "#{error_msg(e.message.capitalize)}\n\n#{parser}"
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def command_registry
          @command_registry ||= {}
        end

        def command(name, summary, &action)
          option_parser = OptionParser.new('', 35, ' ' * 2) do |opt_parser|
            opt_parser.on_tail("-h", "--help", "Show this help message") do
              puts "#{summary}\n\n#{opt_parser}"
              exit
            end
          end
          command_registry[name.to_s] = Command.new(name: name.to_s, summary:, parser: option_parser, action:)
        end

        def commands = command_registry.values

        def summarize_commands
          max_length = commands.map { |cmd| cmd.name.length }.max
          commands.map { |it| "  #{it.name.ljust(max_length)}    #{it.summary}" }.join("\n")
        end
      end

      def command(name) = self.class.command_registry.fetch(name.to_s)
    end
  end
end
