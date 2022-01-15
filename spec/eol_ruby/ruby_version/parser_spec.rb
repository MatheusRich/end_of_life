# frozen_string_literal: true

require "spec_helper"

RSpec.describe EolRuby::RubyVersion::Parser do
  describe ".parse_file" do
    context "with .tool-versions" do
      it "returns the first ruby version defined" do
        result = described_class.parse_file(file_name: ".tool-versions", content: "  ruby 3.0.0\n ruby 2.5.1")

        expect(result).to eq EolRuby::RubyVersion.new("3.0.0")
      end

      it "returns nil if it doesn't have ruby defined" do
        result = described_class.parse_file(file_name: ".tool-versions", content: "python 3.0.0\n")

        expect(result).to be_nil
      end
    end

    context "with unknown file" do
      it "raises an error" do
        expect {
          described_class.parse_file(file_name: "foo.bar", content: "")
        }.to raise_error(ArgumentError, "Unsupported file foo.bar")
      end
    end
  end
end
