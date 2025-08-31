# frozen_string_literal: true

require "spec_helper"

RSpec.describe EndOfLife::Product::Release do
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

  describe "#eol?", vcr: "products-ruby" do
    it "returns true if the release is end of life today" do
      release = EndOfLife::Product::Release.ruby("1.9.3")

      expect(release).to be_eol
    end

    it "returns false if the release is not end of life today" do
      release = EndOfLife::Product::Release.ruby("999999999999", eol_date: Date.today + 1)

      expect(release).not_to be_eol
    end

    it "accepts a custom date" do
      release = EndOfLife::Product::Release.ruby("1.9.3", eol_date: Date.parse("2015-02-23"))
      day_before_eol_date = release.eol_date.prev_day

      result = release.eol?(at: release.eol_date)
      result2 = release.eol?(at: day_before_eol_date)

      expect(result).to be true
      expect(result2).to be false
    end
  end

  describe "#<=>" do
    it "compares ruby releases" do
      older_release = EndOfLife::Product::Release.ruby("1.9.0")
      middle_release = EndOfLife::Product::Release.ruby("2.0.0")
      newer_vertion = EndOfLife::Product::Release.ruby("2.1.0")

      sorted_releases = [older_release, middle_release, newer_vertion].sort

      expect(sorted_releases).to eq([older_release, middle_release, newer_vertion])
    end
  end

  describe "#to_s" do
    it "returns the release as a string" do
      release = EndOfLife::Product::Release.ruby("2.3.0")

      expect(release.to_s).to eq("2.3.0")
    end
  end
end
