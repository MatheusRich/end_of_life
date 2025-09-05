# frozen_string_literal: true

RSpec.describe EndOfLife::Product, vcr: "products-ruby" do
  describe ".eol_releases_at" do
    it "returns all eol releases at a given date" do
      date = Date.parse("2021-03-31")

      releases = EndOfLife::Product.new("ruby").eol_releases_at(date)
      version_strings = releases.map(&:to_s)

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

  describe ".latest_eol_release" do
    context "without a custom date" do
      it "returns the latest eol version today" do
        ruby_2_eol_date = "2016-02-24"
        travel_to ruby_2_eol_date

        version = EndOfLife::Product.new("ruby").latest_eol_release

        expect(version.to_s).to eq "2.0.0p648"
      end
    end

    context "with a custom date" do
      it "returns the latest eol version at a given date" do
        date = Date.parse("2021-03-31")

        version = EndOfLife::Product.new("ruby").latest_eol_release(at: date)

        expect(version.to_s).to eq "2.5.9"
      end
    end
  end
end
