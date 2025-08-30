require "net/http"
require "rubygems"

module EndOfLife
  module RubyVersion
    extend self
    include Dry::Monads[:try]

    def eol_versions_at(date)
      all_releases.filter { |version| version.eol_date <= date }
    end

    def latest_eol(at: Date.today)
      eol_versions_at(at).max
    end

    def new(version, eol_date: nil)
      Product::Release.new(product: :ruby, version:, eol_date:)
    end

    private

    DB_PATH = File.join(__dir__, "../end_of_life.json")

    def all_releases
      @all_releases ||= fetch_end_of_life_api.value_or(load_file_fallback)
        .dig(:result, :releases)
        .map { |version| new(version[:latest][:name], eol_date: Date.parse(version[:eolFrom])) }
    end

    def fetch_end_of_life_api = Try { API.fetch_product("ruby") }

    def load_file_fallback
      JSON.parse(File.read(DB_PATH), symbolize_names: true)
    end
  end
end
