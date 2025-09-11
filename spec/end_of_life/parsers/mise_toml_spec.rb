# frozen_string_literal: true

require "spec_helper"

RSpec.describe EndOfLife::Parsers::MiseToml do
  describe ".parse" do
    context "with valid TOML content" do
      it "parses and extracts the [tools] section" do
        toml_content = <<~TOML
          [tools]
          ruby = "3.1.2"
        TOML

        result = described_class.parse(toml_content)

        expect(result).to eq({"ruby" => "3.1.2"})
      end
    end

    context "when [tools] section is missing" do
      it "returns nil" do
        toml_content = <<~TOML
          [other_section]
          key = "value"
        TOML

        result = described_class.parse(toml_content)

        expect(result).to be_nil
      end
    end

    context "with invalid TOML content" do
      it "raises a PerfectTOML::ParseError" do
        invalid_toml_content = <<~TOML
          [tools
          ruby = "3.1.2"
        TOML

        result = described_class.parse(invalid_toml_content)

        expect(result).to be_nil
      end
    end
  end
end
