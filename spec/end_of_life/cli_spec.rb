# frozen_string_literal: true

RSpec.describe EndOfLife::CLI do
  describe "#call" do
    context "without options" do
      it "defaults to scanning" do
        cli = EndOfLife::CLI.new

        expect { cli.call([]) }.to abort_with(/Please set GITHUB_TOKEN environment variable/)
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

    private

    def exit_with_code(code)
      raise_error(SystemExit) { |error| expect(error.status).to eq(code) }
    end

    def abort_with(message)
      raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.message).to match(message)
      end.and output(message).to_stderr
    end
  end
end
