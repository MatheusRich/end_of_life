require "optparse"

module EndOfLife
  module Options
    def self.from(argv)
      options = {product: Product.find("ruby"), max_eol_date: Date.today, skip_archived: true}
      OptionParser.new do |parser|
        options[:parser] = parser

        parser.banner = "Usage: end_of_life [options]"

        product_names = EndOfLife.products.map(&:name)
        parser.on("-p NAME", "--product NAME", /#{product_names.join("|")}/i, "Sets the product to scan for (default: ruby). Supported products are: #{product_names.join(", ")}.") do |name|
          options[:product] = Product.find(name)
        end

        parser.on("--exclude=NAME,NAME2", Array, "Exclude repositories containing a certain word in its name. You can specify up to five words.") do |excludes|
          options[:excludes] = excludes.first(5)
        end

        parser.on("--public-only", "Searches only public repositories") do
          options[:visibility] = :public
        end

        parser.on("--private-only", "Searches only private repositories") do
          options[:visibility] = :private
        end

        parser.on("--repo=USER/REPO", "--repository=USER/REPO", "Searches a specific repository") do |repository|
          options[:repository] = repository
        end

        parser.on("--org=ORG,ORG2...", "--organization=ORG,ORG2", Array, "Searches within specific organizations") do |organizations|
          options[:organizations] = organizations
        end

        parser.on("-u NAME", "--user=NAME", "Sets the user used on the repository search") do |user|
          options[:user] = user
        end

        parser.on("--max-eol-days-away NUMBER", "Sets the maximum number of days away a version can be from EOL. It defaults to 0.") do |days|
          options[:max_eol_date] = Date.today + days.to_i.abs
        end

        parser.on("--include-archived", "Includes archived repositories on the search") do
          options[:skip_archived] = false
        end

        parser.on("-v", "--version", "Displays end_of_life version") do
          options[:command] = :version
        end

        parser.on("-h", "--help", "Displays this help") do
          options[:command] = :help
        end
      end.parse!(argv)

      options
    rescue OptionParser::ParseError => e
      {command: :print_error, error: e}
    end
  end
end
