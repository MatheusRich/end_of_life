# frozen_string_literal: true

RSpec.describe EndOfLife::Scanner do
  describe ".scan" do
    context "when no repositories are found with EOL Ruby" do
      it "displays the correct message" do
        allow(EndOfLife::Repository).to receive(:fetch).and_return(
          Dry::Monads::Success([])
        )

        options = {
          language: "ruby",
          user: "test_user",
          max_eol_date: Date.today
        }

        expect {
          EndOfLife::Scanner.scan(options)
        }.to output(/No repositories using EOL Ruby\./).to_stdout
          .and raise_no_error
      end
    end

    context "when Repository.fetch fails" do
      it "aborts with error message" do
        error_message = "API rate limit exceeded"
        allow(EndOfLife::Repository).to receive(:fetch).and_return(
          Dry::Monads::Failure(error_message)
        )

        options = {
          language: "ruby",
          user: "test_user",
          max_eol_date: Date.today
        }

        expect(EndOfLife::Scanner).to receive(:abort).with(/#{error_message}/)

        EndOfLife::Scanner.scan(options)
      end
    end
  end
end
