# frozen_string_literal: true

require "spec_helper"

RSpec.describe EndOfLife::VersionDetectors::Nodejs do
  describe ".detect" do
    [".nvmrc", ".node-version"].each do |filename|
      context "with #{filename}" do
        it "returns node version defined" do
          result = described_class.detect(EndOfLife::InMemoryFile.new(filename, "20"))

          expect(result).to eq EndOfLife::Product::Release.new(product: "nodejs", version: "20")
        end

        it "removes the 'v' prefix" do
          result = described_class.detect(EndOfLife::InMemoryFile.new(filename, "v20\n"))

          expect(result).to eq EndOfLife::Product::Release.new(product: "nodejs", version: "20")
        end

        it "returns nil if the version is invalid" do
          result = described_class.detect(EndOfLife::InMemoryFile.new(filename, "not-a-version"))

          expect(result).to be_nil
        end

        it "returns nil if the file is empty" do
          result = described_class.detect(EndOfLife::InMemoryFile.new(filename, ""))

          expect(result).to be_nil
        end
      end
    end

    context "with .tool-versions" do
      it "returns the last node version defined" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", "  nodejs 12.0.0\n nodejs 13.0.0"))

        expect(result).to eq EndOfLife::Product::Release.new(product: "nodejs", version: "13.0.0")
      end

      it "returns nil if it doesn't have node defined" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", "python 3.0.0\n"))

        expect(result).to be_nil
      end

      it "returns nil if the file is empty" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", ""))

        expect(result).to be_nil
      end
    end

    context "with mise.toml" do
      it "returns the node version defined" do
        mise_toml = <<~TOML
          [tools]
          node = "18.0.0"
        TOML

        result = described_class.detect(EndOfLife::InMemoryFile.new("mise.toml", mise_toml))

        expect(result).to eq EndOfLife::Product::Release.new(product: "nodejs", version: "18.0.0")
      end

      context "when node is not defined" do
        it "returns nil" do
          mise_toml = <<~TOML
            [tools]
            python = "3.9.1"
          TOML

          result = described_class.detect(EndOfLife::InMemoryFile.new("mise.toml", mise_toml))

          expect(result).to be_nil
        end
      end
    end

    context "with unknown file" do
      it "returns nil" do
        result = described_class.detect(EndOfLife::InMemoryFile.new("foo.bar", "foo"))

        expect(result).to be_nil
      end
    end
  end
end
