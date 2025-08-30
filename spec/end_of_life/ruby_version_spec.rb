# frozen_string_literal: true

RSpec.describe EndOfLife::RubyVersion do
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

  describe ".initialize" do
    it "accepts a string version" do
      version = "2.3.0"

      result = EndOfLife::Product::Release.ruby(version)

      expect(result.version).to eq(Gem::Version.new(version))
    end

    it "accepts an eol date" do
      today = Date.today

      result = EndOfLife::Product::Release.ruby("2.3.0", eol_date: today)

      expect(result.eol_date).to eq(today)
    end

    it "accepts a Gem::Version" do
      version = Gem::Version.new("2.3.0")

      result = EndOfLife::Product::Release.ruby(version)

      expect(result.version).to eq(version)
    end

    it "freezes the object" do
      result = EndOfLife::Product::Release.ruby("2.3.0")

      expect(result).to be_frozen
    end
  end

  describe "#eol?" do
    it "returns true if the version is end of life today" do
      version = EndOfLife::Product::Release.ruby("1.9.3")

      expect(version).to be_eol
    end

    it "returns false if the version is not end of life today" do
      version = EndOfLife::Product::Release.ruby("999999999999", eol_date: Date.today + 1)

      expect(version).not_to be_eol
    end

    it "accepts a custom date" do
      version = EndOfLife::Product::Release.ruby("1.9.3", eol_date: Date.parse("2015-02-23"))
      day_before_eol_date = version.eol_date.prev_day

      result = version.eol?(at: version.eol_date)
      result2 = version.eol?(at: day_before_eol_date)

      expect(result).to be true
      expect(result2).to be false
    end
  end

  describe "#<=>" do
    it "compares ruby versions" do
      older_version = EndOfLife::Product::Release.ruby("1.9.0")
      middle_version = EndOfLife::Product::Release.ruby("2.0.0")
      newer_vertion = EndOfLife::Product::Release.ruby("2.1.0")

      sorted_versions = [older_version, middle_version, newer_vertion].sort

      expect(sorted_versions).to eq([older_version, middle_version, newer_vertion])
    end
  end

  describe "#to_s" do
    it "returns the version as a string" do
      version = EndOfLife::Product::Release.ruby("2.3.0")

      expect(version.to_s).to eq("2.3.0")
    end
  end

  private

  def travel_to(date)
    date = Date.parse(date)

    allow(Date).to receive(:today).and_return(date)
  end
end
