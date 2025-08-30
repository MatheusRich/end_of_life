# frozen_string_literal: true

RSpec.describe EndOfLife::RubyVersion, vcr: "products-ruby" do
  describe ".eol_versions_at" do
    it "returns all eol versions at a given date" do
      date = Date.parse("2021-03-31")

      versions = EndOfLife::RubyVersion.eol_versions_at(date)
      version_strings = versions.map(&:to_s)

      expect(version_strings).to match_array [
        "2.5.9",
        "2.4.10",
        "2.3.8",
        "2.2.10",
        "2.1.10",
        "2.0.0p648",
        "1.9.3p551"
      ]
    end
  end

  describe ".latest_eol" do
    context "without a custom date" do
      it "returns the latest eol version today" do
        ruby_2_eol_date = "2016-02-24"
        travel_to ruby_2_eol_date

        version = EndOfLife::RubyVersion.latest_eol

        expect(version.to_s).to eq "2.0.0p648"
      end
    end

    context "with a custom date" do
      it "returns the latest eol version at a given date" do
        date = Date.parse("2021-03-31")

        version = EndOfLife::RubyVersion.latest_eol(at: date)

        expect(version.to_s).to eq "2.5.9"
      end
    end
  end
end
