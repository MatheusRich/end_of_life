# frozen_string_literal: true

RSpec.describe EndOfLife::Repository do
  describe "#fetch" do
    it "fetches all 200 repositories from an account despite exceeding page size" do
      repositories = VCR.use_cassette("many_repositories") do
        with_env GITHUB_TOKEN: "REDACTED" do
          EndOfLife::Repository.fetch(language: "ruby", user: nil, organizations: nil, repository: nil)
        end
      end

      expect(repositories.value!.count).to eq(200)
    end
  end
end
