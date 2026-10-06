# frozen_string_literal: true

RSpec.describe EndOfLife::Result do
  describe EndOfLife::Result::Success do
    subject(:result) { described_class.new("value") }

    it "is successful", :aggregate_failures do
      expect(result.successful?).to be true
      expect(result.failed?).to be false
    end

    it "has a value and no error", :aggregate_failures do
      expect(result.value).to eq "value"
      expect(result.error).to be_nil
    end

    it "answers the block of on_success" do
      expect(result.on_success { |value| "#{value} and more" }).to eq "value and more"
    end

    it "skips the block of on_failure" do
      expect(result.on_failure { raise "unexpected call" }).to be result
    end
  end

  describe EndOfLife::Result::Failure do
    subject(:result) { described_class.new("error") }

    it "is failed", :aggregate_failures do
      expect(result.successful?).to be false
      expect(result.failed?).to be true
    end

    it "has an error and no value", :aggregate_failures do
      expect(result.error).to eq "error"
      expect { result.value }.to raise_error(RuntimeError, "No value for failed result")
    end

    it "skips the block of on_success" do
      expect(result.on_success { raise "unexpected call" }).to be result
    end

    it "answers the block of on_failure" do
      expect(result.on_failure { |error| "#{error} and more" }).to eq "error and more"
    end
  end
end
