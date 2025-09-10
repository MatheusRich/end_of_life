# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe EndOfLife::VersionDetectors::Rails do
  describe "Gemfile.lock detection" do
    it "detects Rails version from Gemfile.lock" do
      file = EndOfLife::InMemoryFile.new("Gemfile.lock", <<~GEMFILE)
        GEM
          remote: https://rubygems.org/
          specs:
            rails (6.1.4)
              actionpack (= 6.1.4)
              activejob (= 6.1.4)
              activemodel (= 6.1.4)
              activerecord (= 6.1.4)
              activesupport (= 6.1.4)
              railties (= 6.1.4)
      GEMFILE

      result = described_class.detect(file)

      expect(result).to eq(EndOfLife::Product::Release.new(product: "rails", version: "6.1.4"))
    end

    context "when running outside of a Bundler project" do
      it "returns nil" do
        file = EndOfLife::InMemoryFile.new("Gemfile.lock", <<~GEMFILE)
          GEM
            remote: https://rubygems.org/
            specs:
              rails (6.1.4)
                actionpack (= 6.1.4)
                activejob (= 6.1.4)
                activemodel (= 6.1.4)
                activerecord (= 6.1.4)
                activesupport (= 6.1.4)
                railties (= 6.1.4)
        GEMFILE

        # Simulate running this outside of a Bundler project. This is needed
        # because this variable is memoized and we're using bundler to run the
        # tests.
        Bundler.instance_variable_set(:@root, nil)
        result = nil
        Dir.mktmpdir do |tmp_dir|
          Dir.chdir(tmp_dir) do
            with_env BUNDLE_GEMFILE: nil do
              result = described_class.detect(file)
            end
          end
        end

        expect(result).to be_nil
      end
    end

    context "when there is no rails gem" do
      it "returns nil" do
        file = EndOfLife::InMemoryFile.new("Gemfile.lock", <<~GEMFILE)
          GEM
            remote: https://rubygems.org/
            specs:
              rake (13.0.6)
        GEMFILE

        result = described_class.detect(file)

        expect(result).to be_nil
      end
    end

    context "when the lock file is invalid" do
      it "returns nil" do
        file = EndOfLife::InMemoryFile.new("Gemfile.lock", "invalid content")

        result = described_class.detect(file)

        expect(result).to be_nil
      end
    end
  end

  describe "Gemfile detection" do
    context "when version is specified explicitly" do
      it "returns the max exact version specified" do
        file = EndOfLife::InMemoryFile.new("Gemfile", <<~GEMFILE)
          gem "rails", "5.0", "7.0", "6.0", "~> 8.0", ">= 4.0"
        GEMFILE

        result = described_class.detect(file)

        expect(result).to eq(EndOfLife::Product::Release.new(product: "rails", version: "7.0"))
      end
    end

    context "when the gem doesn't have an exact version specified" do
      it "returns nil" do
        file = EndOfLife::InMemoryFile.new("Gemfile", <<~GEMFILE)
          gem "rails", ">= 13.0.6", "~> 7.0"
        GEMFILE

        result = described_class.detect(file)

        expect(result).to be_nil
      end
    end

    context "when the gem doesn't have a version specified" do
      it "returns nil" do
        file = EndOfLife::InMemoryFile.new("Gemfile", <<~GEMFILE)
          gem "rake"
        GEMFILE

        result = described_class.detect(file)

        expect(result).to be_nil
      end
    end

    context "when there is no rails gem" do
      it "returns nil" do
        file = EndOfLife::InMemoryFile.new("Gemfile", <<~GEMFILE)
          gem "rake", "13.0.6"
        GEMFILE

        result = described_class.detect(file)

        expect(result).to be_nil
      end
    end

    context "when the Gemfile is invalid" do
      it "returns nil" do
        file = EndOfLife::InMemoryFile.new("Gemfile", "invalid content")

        result = described_class.detect(file)

        expect(result).to be_nil
      end
    end
  end
end
