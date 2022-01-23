# frozen_string_literal: true

require "climate_control"
require "ostruct"

RSpec.describe EndOfLife::Repository do
  describe "#fetch" do
    context "given an account with 200 end of life repositories" do
      subject(:repositories) do
        VCR.use_cassette("many_repositories") do
          EndOfLife::Repository.fetch(language: "ruby", user: nil, organizations: nil, repository: nil)
        end
      end

      it "returns Success with the collection of repositories" do
        expect(repositories.value_or(nil).count).to eq(200)
      end
    end
  end
end
