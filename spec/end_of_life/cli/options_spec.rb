# frozen_string_literal: true

RSpec.describe EndOfLife::CLI::Options do
  describe ".from" do
    it "saves the parser inside the options" do
      input = []

      options = described_class.from(input)

      expect(options[:parser]).to be_a OptionParser
    end

    context "when setting the maximum number of eol days away" do
      it "sets the max EOL date to the given number of days from now" do
        input = ["--max-eol-days-away", "10"]

        options = described_class.from(input)

        expect(options[:max_eol_date]).to eq(Date.today + 10)
      end

      it "ignores negative numbers" do
        input = ["--max-eol-days-away", "-10"]

        options = described_class.from(input)

        expect(options[:max_eol_date]).to eq(Date.today + 10)
      end
    end

    context "when setting the organizations" do
      it "converts the input to an array of strings" do
        input = ["--organization", "org1,org2"]

        options = described_class.from(input)

        expect(options[:organizations]).to match_array ["org1", "org2"]
      end
    end

    context "with --user" do
      it "sets the user used on searches" do
        input = ["--user", "someuser"]

        options = described_class.from(input)

        expect(options[:user]).to eq "someuser"
      end
    end

    context "with --repository" do
      it "sets the repository used on searches" do
        input = ["--repository", "some_repository"]

        options = described_class.from(input)

        expect(options[:repository]).to eq "some_repository"
      end
    end

    context "with --public-only" do
      it "sets the search repositories visibility to public" do
        input = ["--public-only"]

        options = described_class.from(input)

        expect(options[:visibility]).to eq :public
      end
    end

    context "with --private-only" do
      it "sets the search repositories visibility to private" do
        input = ["--private-only"]

        options = described_class.from(input)

        expect(options[:visibility]).to eq :private
      end
    end

    context "with --exclude" do
      it "sets exclude words" do
        input = ["--exclude", "word1,word2"]

        options = described_class.from(input)

        expect(options[:excludes]).to eq ["word1", "word2"]
      end

      it "has a limit of five words" do
        input = ["--exclude", "word1,word2,word3,word4,word5,word6"]

        options = described_class.from(input)

        expect(options[:excludes]).to eq ["word1", "word2", "word3", "word4", "word5"]
      end
    end

    context "with --include-archived" do
      it "includes archived repositories" do
        input = ["--include-archived"]

        options = described_class.from(input)

        expect(options[:skip_archived]).to be false
      end
    end

    context "with no options (i.e., default options)" do
      it "sets max EOL date to today" do
        input = []

        options = described_class.from(input)

        expect(options[:max_eol_date]).to eq(Date.today)
      end

      it "skips archived repositories" do
        input = []

        options = described_class.from(input)

        expect(options[:skip_archived]).to be true
      end
    end

    context "with an invalid option" do
      it "sets command to print error", :aggregate_failures do
        input = ["--invalid-option"]

        options = described_class.from(input)

        expect(options[:command]).to eq(:abort)
        expect(options[:error]).to include("\e[31m[ERROR] \e[0m invalid option: --invalid-option")
      end
    end
  end
end
