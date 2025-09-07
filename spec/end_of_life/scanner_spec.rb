# frozen_string_literal: true

RSpec.describe EndOfLife::Scanner do
  include Dry::Monads[:result, :maybe]

  describe ".scan" do
    context "when no repositories are found with EOL product" do
      it "displays the correct message" do
        allow(EndOfLife::Repository).to receive(:search).and_return(
          Dry::Monads::Success([])
        )

        options = {
          product: EndOfLife::Product.find("ruby"),
          user: "test_user",
          max_eol_date: Date.today
        }

        expect {
          EndOfLife::Scanner.scan(options)
        }.to output(/No repositories using EOL Ruby\./).to_stdout
          .and raise_no_error
      end
    end

    context "when Repository.search fails" do
      it "aborts with error message" do
        error_message = "API rate limit exceeded"
        allow(EndOfLife::Repository).to receive(:search).and_return(
          Dry::Monads::Failure(error_message)
        )

        options = {
          product: EndOfLife::Product.find("ruby"),
          user: "test_user",
          max_eol_date: Date.today
        }

        expect { EndOfLife::Scanner.scan(options) }
          .to abort_with(/#{error_message}/)
      end
    end
  end
end
