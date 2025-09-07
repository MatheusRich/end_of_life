# frozen_string_literal: true

RSpec.describe EndOfLife::CLI do
  describe "#call" do
    context "without options" do
      it "defaults to scanning Ruby" do
        cli = EndOfLife::CLI.new

        expect {
          expect { cli.call([]) }.to output(/Searching repositories with Ruby.../).to_stdout
        }.to abort_with(/Please set GITHUB_TOKEN environment variable/)
      end
    end

    context "with product option" do
      it "scans for the specified product" do
        cli = EndOfLife::CLI.new

        expect {
          expect { cli.call(["--product=rails"]) }.to output(/Searching repositories with Rails.../).to_stdout
        }.to abort_with(/Please set GITHUB_TOKEN environment variable/)
      end

      context "with an unknown product" do
        it "exits with error message" do
          cli = EndOfLife::CLI.new

          expect { cli.call(["--product=unknown_product"]) }
            .to abort_with(/invalid argument: --product=unknown_product/)
        end
      end
    end

    context "with version option" do
      it "prints the version" do
        cli = EndOfLife::CLI.new

        expect { cli.call(["-v"]) }.to output("end_of_life v#{EndOfLife::VERSION}\n").to_stdout
      end
    end

    context "with help option" do
      it "prints the help banner" do
        cli = EndOfLife::CLI.new

        expect { cli.call(["-h"]) }.to output(/Usage: end_of_life \[options\]/).to_stdout
      end
    end

    context "with invalid option" do
      it "exits with error message" do
        cli = EndOfLife::CLI.new

        expect { cli.call(["--unknown-option"]) }
          .to exit_with_code(1)
          .and output(/invalid option: --unknown-option/).to_stderr
      end
    end
  end
end
