# frozen_string_literal: true

RSpec.describe EndOfLife::Options do
  describe ".from" do
    it "saves the parser inside the options" do
      input = []

      options = EndOfLife::Options.from(input)

      expect(options[:parser]).to be_a OptionParser
    end

    context "when setting the maximum number of eol days away" do
      it "sets the max EOL date to the given number of days from now" do
        input = ["--max-eol-days-away", "10"]

        options = EndOfLife::Options.from(input)

        expect(options[:max_eol_date]).to eq(Date.today + 10)
      end

      it "ignores negative numbers" do
        input = ["--max-eol-days-away", "-10"]

        options = EndOfLife::Options.from(input)

        expect(options[:max_eol_date]).to eq(Date.today + 10)
      end
    end

    context "when setting the organizations" do
      it "converts the input to an array of strings" do
        input = ["--organization", "org1,org2"]

        options = EndOfLife::Options.from(input)

        expect(options[:organizations]).to match_array ["org1", "org2"]
      end
    end

    context "with --user" do
      it "sets the user used on searches" do
        input = ["--user", "someuser"]

        options = EndOfLife::Options.from(input)

        expect(options[:user]).to eq "someuser"
      end
    end

    context "with --repository" do
      it "sets the repository used on searches" do
        input = ["--repository", "some_repository"]

        options = EndOfLife::Options.from(input)

        expect(options[:repository]).to eq "some_repository"
      end
    end

    context "with no options" do
      it "sets max EOL date to today" do
        input = []

        options = EndOfLife::Options.from(input)

        expect(options[:max_eol_date]).to eq(Date.today)
      end
    end

    context "with an invalid option" do
      it "sets command to print error", :aggregate_failures do
        input = ["--invalid-option"]

        options = EndOfLife::Options.from(input)

        expect(options[:command]).to eq(:print_error)
        expect(options[:error]).to be_a(OptionParser::ParseError)
      end
    end
  end
end
