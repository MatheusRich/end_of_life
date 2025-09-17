require "argument_parser"
require "date"

module EndOfLife
  class CLI
    include Command::Registry
    extend Helpers::Terminal
    include Helpers::Terminal

    command :scan, "Find projects using end-of-life software" do |argv, opt_parser|
      options = {max_eol_date: Date.today, skip_archived: true}

      opt_parser.banner = "Usage: end_of_life scan PRODUCT [OPTIONS]"
      opt_parser.on("--exclude=NAME,NAME2", Array, "Exclude repositories containing a certain word in their name. You can specify up to five words.") do |excludes|
        options[:excludes] = excludes.first(5)
      end

      opt_parser.on("--public-only", "Searches only public repositories") do
        options[:visibility] = :public
      end

      opt_parser.on("--private-only", "Searches only private repositories") do
        options[:visibility] = :private
      end

      opt_parser.on("--repo=USER/REPO", "--repository=USER/REPO", "Searches a specific repository") do |repository|
        options[:repository] = repository
      end

      opt_parser.on("--org=ORG,ORG2...", "--organization=ORG,ORG2", Array, "Searches within specific organizations") do |organizations|
        options[:organizations] = organizations
      end

      opt_parser.on("-u NAME", "--user=NAME", "Sets the user used on the repository search") do |user|
        options[:user] = user
      end

      opt_parser.on("--max-eol-days-away NUMBER", "Sets the maximum number of days away a version can be from EOL.") do |days|
        options[:max_eol_date] = Date.today + days.to_i.abs
      end

      opt_parser.on("--include-archived", "Includes archived repositories on the search") do
        options[:skip_archived] = false
      end
      opt_parser.parse!(argv)

      argument_parser = ArgumentParser.build do
        required :product, pattern: EndOfLife.products_pattern
      end
      name = argument_parser.parse!(argv).fetch(:product)

      Scanner.scan(Product.find(name), options)
    end

    command :check, "Check if specific product releases are end-of-life" do |argv, opt_parser|
      options = {max_eol_date: Date.today}
      opt_parser.banner = "Usage: end_of_life check PRODUCT@VERSION PRODUCT2@VERSION... [OPTIONS]"
      opt_parser.on("--max-eol-days-away NUMBER", "Sets the maximum number of days away a version can be from EOL.") do |days|
        options[:max_eol_date] = Date.today + days.to_i.abs
      end
      opt_parser.parse!(argv)

      argument_parser = ArgumentParser.build do
        rest :releases, pattern: EndOfLife.products_pattern(suffix: "@"), min: 1
      end
      args = argument_parser.parse!(argv)

      Check.run(args[:releases], options)
    end

    command :help, "Show this help message" do |args, _|
      io = args.include?('--error') ? $stderr : $stdout

      io.puts <<~HELP
        Usage: end_of_life COMMAND [OPTIONS]

        Commands:
        #{summarize_commands}

        Options:
          -h, --help       Show this help message
          -v, --version    Show end_of_life version

        Pass -h/--help to commands to see their specific options.
      HELP
    end

    command :version, "Show end_of_life version" do
      puts "end_of_life v#{EndOfLife::VERSION}"
    end

    def call(argv)
      find_command(argv).run(argv)
    rescue ArgumentError, ArgumentParser::Error => e
      abort_with(e.message.capitalize)
    end

    private

    def find_command(argv)
      parse_args(argv).then { |args| command(args[:command]) }
    end

    def parse_args(argv)
      argument_parser = ArgumentParser.build do
        required :command, pattern: {
          "-h" => :help,
          "-v" => :version,
          "--help" => :help,
          "--version" => :version,
          **EndOfLife::CLI.commands.to_h { |cmd| [cmd.name, cmd.name] }
        }
      end

      argument_parser.parse!(argv)
    end

    def abort_with(message)
      warn error_msg(message)
      command(:help).run(['--error'])
      exit 1
    end
  end
end
