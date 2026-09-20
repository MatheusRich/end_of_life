# frozen_string_literal: true

RSpec.describe EndOfLife::Parsers::ToolVersions do
  describe ".parse" do
    it "returns the version for each tool" do
      result = described_class.parse("ruby 3.2.0\nnodejs 18.1.0\n")

      expect(result).to eq({"ruby" => Gem::Version.new("3.2.0"), "nodejs" => Gem::Version.new("18.1.0")})
    end

    it "ignores comments and empty lines" do
      result = described_class.parse("# a comment\n\nruby 3.2.0 # inline\n")

      expect(result).to eq({"ruby" => Gem::Version.new("3.2.0")})
    end

    it "ignores versions that are not numbers", :aggregate_failures do
      expect(described_class.parse("nodejs lts\nruby 3.2.0\n")).to eq({"ruby" => Gem::Version.new("3.2.0")})
      expect(described_class.parse("ruby latest")).to eq({})
      expect(described_class.parse("ruby system")).to eq({})
      expect(described_class.parse("ruby ref:v3.2.0")).to eq({})
    end

    it "ignores a tool with no version" do
      result = described_class.parse("ruby\nnodejs 18.1.0\n")

      expect(result).to eq({"nodejs" => Gem::Version.new("18.1.0")})
    end

    it "returns an empty hash for an empty file" do
      expect(described_class.parse("")).to eq({})
    end
  end
end
