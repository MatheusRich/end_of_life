require "net/http"
require "rubygems"

module EndOfLife
  module RubyVersion
    extend self
    include Dry::Monads[:try]

    def eol_versions_at(date)
      all_versions.filter { |version| version.eol_date <= date }
    end

    def latest_eol(at: Date.today)
      eol_versions_at(at).max
    end

    def new(version, eol_date: nil)
      Product::Release.new(product: :ruby, version:, eol_date:)
    end

    private

    EOL_API_URL = "https://endoflife.date/api/ruby.json"
    DB_PATH = File.join(__dir__, "../end_of_life.json")

    def all_versions
      @all_versions ||= fetch_end_of_life_api.value_or(load_file_fallback)
        .then { |json| JSON.parse(json, symbolize_names: true) }
        .map { |version| new(version[:latest], eol_date: Date.parse(version[:eol])) }
    end

    def fetch_end_of_life_api
      Try { Net::HTTP.get URI(EOL_API_URL) }
    end

    def load_file_fallback
      File.read(DB_PATH)
    end
  end
end
