require "json"
require "net/http"

module EndOfLife
  module API
    extend self

    BASE_URL = "https://endoflife.date/api/v1/"

    def fetch_product(product) = get("products/#{product}")

    private

    def get(path)
      response = Net::HTTP.get(URI("#{BASE_URL}#{path}"))

      JSON.parse(response, symbolize_names: true)
    end
  end
end
