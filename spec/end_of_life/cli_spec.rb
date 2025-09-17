# frozen_string_literal: true

RSpec.describe EndOfLife::CLI do
  describe "#call" do
    context "with product argument" do
      it "scans for the specified product" do
        with_env GITHUB_TOKEN: "foo" do
          fake_github = instance_spy(Octokit::Client)
          allow(fake_github).to receive(:search_code).and_return(double(total_count: 0, items: []))
          allow(Octokit::Client).to receive(:new).and_return(fake_github)
          cli = EndOfLife::CLI.new

          cli.call(["scan", "ruby"])

          expect(fake_github).to have_received(:search_code).with(/#{EndOfLife::Product.find("ruby").search_query}/)
        end
      end

      context "with an unknown product" do
        it "exits with error message" do
          cli = EndOfLife::CLI.new

          expect { cli.call(["scan", "unknown_product"]) }
            .to abort_with(/Invalid argument: unknown_product/)
        end
      end
    end

    context "without options" do
      it "aborts and prints help" do
        cli = EndOfLife::CLI.new

        expect { cli.call(["scan"]) }
          .to exit_with_code(1)
          .and output(/Usage: end_of_life scan PRODUCT \[OPTIONS\]/).to_stderr
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

        expect { cli.call(["-h"]) }.to output(/Usage: end_of_life COMMAND \[OPTIONS\]/).to_stdout
      end
    end

    context "with invalid option" do
      it "exits with error message" do
        cli = EndOfLife::CLI.new

        expect { cli.call(["scan", "--unknown-option"]) }
          .to exit_with_code(1)
          .and output(/Invalid option: --unknown-option/).to_stderr
      end
    end

    context "with invalid command" do
      it "aborts and prints help" do
        cli = EndOfLife::CLI.new

        expect { cli.call(["foobar"]) }
          .to exit_with_code(1)
          .and output(/Usage: end_of_life COMMAND \[OPTIONS\]/).to_stderr
      end
    end
  end
end
