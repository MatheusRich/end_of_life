# frozen_string_literal: true

require "spec_helper"

RSpec.describe EndOfLife::VersionDetectors::Python do
  describe ".detect" do
    context "with .python-version" do
      it "returns python version defined" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".python-version", "3.9"))

        expect(result).to eq EndOfLife::Product::Release.new(product: "python", version: "3.9")
      end

      it "strips whitespace" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".python-version", "  3.9.1\n"))

        expect(result).to eq EndOfLife::Product::Release.new(product: "python", version: "3.9.1")
      end

      it "returns nil if the version is invalid" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".python-version", "not-a-version"))

        expect(result).to be_nil
      end

      it "returns nil if the file is empty" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".python-version", ""))

        expect(result).to be_nil
      end
    end

    context "with .tool-versions" do
      it "returns the last python version defined" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", "  python 3.9.0\n python 3.10.0"))

        expect(result).to eq EndOfLife::Product::Release.new(product: "python", version: "3.10.0")
      end

      it "returns nil if it doesn't have python defined" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", "nodejs 18.0.0\n"))

        expect(result).to be_nil
      end

      it "returns nil if the file is empty" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", ""))

        expect(result).to be_nil
      end
    end

    context "with mise.toml" do
      it "returns the python version defined" do
        mise_toml = <<~TOML
          [tools]
          python = "3.9.1"
        TOML

        result = described_class.detect(EndOfLife::InMemoryFile.new("mise.toml", mise_toml))

        expect(result).to eq EndOfLife::Product::Release.new(product: "python", version: "3.9.1")
      end

      context "when python is not defined" do
        it "returns nil" do
          mise_toml = <<~TOML
            [tools]
            node = "18.0.0"
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
