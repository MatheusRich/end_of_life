# frozen_string_literal: true

require "spec_helper"

RSpec.describe EndOfLife::VersionDetectors::Ruby do
  describe ".detect" do
    context "with .ruby-version" do
      it "returns ruby version defined" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".ruby-version", "3.0.0"))

        expect(result).to eq EndOfLife::Product::Release.ruby("3.0.0")
      end

      it "removes the 'ruby-' prefix" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".ruby-version", "ruby-2.0.0\n"))

        expect(result).to eq EndOfLife::Product::Release.ruby("2.0.0")
      end

      it "returns nil if the file is empty" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".ruby-version", ""))

        expect(result).to be_nil
      end
    end

    context "with Gemfile.lock" do
      it "returns the ruby version defined" do
        gemfile_lock = <<~GEMFILE_LOCK
          GEM
            remote: https://rubygems.org/
            specs:

          PLATFORMS
            x86_64-darwin-20

          DEPENDENCIES

          RUBY VERSION
            ruby 3.0.2p107

          BUNDLED WITH
            2.3.4
        GEMFILE_LOCK

        result = described_class.detect(EndOfLife::InMemoryFile.new("Gemfile.lock", gemfile_lock))

        expect(result).to eq EndOfLife::Product::Release.ruby("3.0.2p107")
      end

      it "returns nil if it doesn't have ruby version defined" do
        gemfile_lock = <<~GEMFILE_LOCK
          GEM
            remote: https://rubygems.org/
            specs:

          PLATFORMS
            x86_64-darwin-20

          DEPENDENCIES

          BUNDLED WITH
            2.3.4
        GEMFILE_LOCK

        result = described_class.detect(EndOfLife::InMemoryFile.new("Gemfile.lock", gemfile_lock))

        expect(result).to be_nil
      end

      it "returns nil if the file is empty" do
        result = described_class.detect(EndOfLife::InMemoryFile.new("Gemfile.lock", ""))

        expect(result).to be_nil
      end
    end

    context "with Gemfile" do
      it "returns the ruby version defined" do
        gemfile = <<~GEMFILE
          ruby "3.0.2"

          source "https://rubygems.org"
        GEMFILE

        result = described_class.detect(EndOfLife::InMemoryFile.new("Gemfile", gemfile))

        expect(result).to eq EndOfLife::Product::Release.ruby("3.0.2")
      end

      it "returns nil if it doesn't have ruby version defined" do
        gemfile = <<~GEMFILE
          source "https://rubygems.org"
        GEMFILE

        result = described_class.detect(EndOfLife::InMemoryFile.new("Gemfile", gemfile))

        expect(result).to be_nil
      end

      it "returns nil if it the ruby version is defined in a file" do
        gemfile = <<~GEMFILE
          source "https://rubygems.org"
          ruby file: ".ruby-version"
        GEMFILE

        result = described_class.detect(EndOfLife::InMemoryFile.new("Gemfile", gemfile))

        expect(result).to be_nil
      end

      it "returns nil if some error occurs while parsing Gemfile" do
        gemfile = <<~GEMFILE
          ruby "3.0.2"

          source "https://rubygems.org"

          gemspec # this will fail, since no gemspec is defined
        GEMFILE

        result = described_class.detect(EndOfLife::InMemoryFile.new("Gemfile", gemfile))

        expect(result).to be_nil
      end

      it "returns nil if the file is empty" do
        gemfile = ""

        result = described_class.detect(EndOfLife::InMemoryFile.new("Gemfile", gemfile))

        expect(result).to be_nil
      end
    end

    context "with .tool-versions" do
      it "returns the first ruby version defined" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", "  ruby 3.0.0\n ruby 2.5.1"))

        expect(result).to eq EndOfLife::Product::Release.ruby("3.0.0")
      end

      it "returns nil if it doesn't have ruby defined" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", "python 3.0.0\n"))

        expect(result).to be_nil
      end

      it "returns nil if the file is empty" do
        result = described_class.detect(EndOfLife::InMemoryFile.new(".tool-versions", ""))

        expect(result).to be_nil
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
