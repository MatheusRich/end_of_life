require "optparse"

module EndOfLife
  module Options
    def self.from(argv)
      options = {max_eol_date: Date.today}

      OptionParser.new do |opts|
        options[:parser] = opts

        opts.banner = "Usage: end_of_life [options]"

        opts.on("--repo=USER/REPO", "--repository=USER/REPO", "Searches a specific repostory") do |repository|
          options[:repository] = repository
        end
        opts.on("-u NAME", "--user=NAME", "Sets the user used on the repository search") do |user|
          options[:user] = user
        end

        opts.on("--max-eol-days-away NUMBER", "Sets the maximum number of days away a version can be from EOL. It defaults to 0.") do |days|
          options[:max_eol_date] = Date.today + days.to_i.abs
        end

        opts.on("-v", "--version", "Displays end_of_life version") do
          options[:command] = :version
        end

        opts.on("-h", "--help", "Displays this help") do
          options[:command] = :help
        end
      end.parse!(argv)

      options
    rescue OptionParser::ParseError => e
      {command: :print_error, error: e}
    end
  end
end
