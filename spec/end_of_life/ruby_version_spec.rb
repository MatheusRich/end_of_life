# frozen_string_literal: true

RSpec.describe EndOfLife::RubyVersion do
  describe ".from_file" do
    it "delegates it to the given parser" do
      parser = spy(:parser)

      EndOfLife::RubyVersion.from_file(
        file_name: "Gemfile.lock",
        content: "some content",
        parser: parser
      )

      expect(parser).to have_received(:parse_file).with(
        file_name: "Gemfile.lock",
        content: "some content"
      )
    end
  end

  describe ".initialize" do
    it "accepts a string version" do
      version = "2.3.0"

      result = EndOfLife::RubyVersion.new(version)

      expect(result.version).to eq(Gem::Version.new("2.3.0"))
    end

    it "accepts a Gem::Version" do
      version = Gem::Version.new("2.3.0")

      result = EndOfLife::RubyVersion.new(version)

      expect(result.version).to eq(Gem::Version.new("2.3.0"))
    end

    it "freezes the object" do
      result = EndOfLife::RubyVersion.new("2.3.0")

      expect(result).to be_frozen
    end
  end

  describe "#eol?" do
    it "returns true if the version is end of life" do
      version = EndOfLife::RubyVersion.new("1.9.3")

      expect(version).to be_eol
    end

    it "returns false if the version is not end of life" do
      version = EndOfLife::RubyVersion.new("999999999999")

      expect(version).not_to be_eol
    end
  end

  describe "#<=>" do
    it "compares ruby versions" do
      older_version = EndOfLife::RubyVersion.new("1.9.0")
      middle_version = EndOfLife::RubyVersion.new("2.0.0")
      newer_vertion = EndOfLife::RubyVersion.new("2.1.0")

      sorted_versions = [older_version, middle_version, newer_vertion].sort

      expect(sorted_versions).to eq([older_version, middle_version, newer_vertion])
    end
  end

  describe "#to_s" do
    it "returns the version as a string" do
      version = EndOfLife::RubyVersion.new("2.3.0")

      expect(version.to_s).to eq("2.3.0")
    end
  end
end
