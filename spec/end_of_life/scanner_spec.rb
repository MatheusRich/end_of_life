# frozen_string_literal: true

RSpec.describe EndOfLife::Scanner do
  describe ".scan" do
    context "when the search finds no repository" do
      it "reports none of them", :capture_io do
        allow(EndOfLife::Repository).to receive(:search).and_return(Dry::Monads::Success([]))

        expect { scan_ruby }.to raise_no_error
        expect($stdout.string).to include("No repositories using EOL Ruby.")
      end
    end

    context "when some repositories use an EOL version" do
      it "reports only those", :aggregate_failures, :capture_io, vcr: "products-ruby" do
        stub_search_and_fetch("thoughtbot/old" => "2.5.0", "thoughtbot/new" => "9999999")

        expect { scan_ruby }.to exit_with_code(1)
        expect($stdout.string).to include("thoughtbot/old")
        expect($stdout.string).not_to include("thoughtbot/new")
      end
    end

    context "when every repository uses a supported version" do
      it "reports none of them", :capture_io, vcr: "products-ruby" do
        stub_search_and_fetch("thoughtbot/new" => "9999999")

        expect { scan_ruby }.to raise_no_error
        expect($stdout.string).to include("No repositories using EOL Ruby.")
      end
    end

    context "when Repository.search fails" do
      it "aborts with the error message" do
        allow(EndOfLife::Repository).to receive(:search).and_return(
          Dry::Monads::Failure("API rate limit exceeded")
        )

        expect { scan_ruby }.to abort_with(/API rate limit exceeded/)
      end
    end

    context "when Repository.fetch fails" do
      it "aborts with the error message" do
        allow(EndOfLife::Repository).to receive(:search).and_return(
          Dry::Monads::Success(["thoughtbot/paperclip"])
        )
        allow(EndOfLife::Repository).to receive(:fetch).and_return(
          Dry::Monads::Failure("Unexpected error: connection reset")
        )

        expect { scan_ruby }.to abort_with(/connection reset/)
      end
    end
  end

  private

  def scan_ruby
    EndOfLife::Scanner.scan(EndOfLife::Product.find("ruby"), {max_eol_date: Date.today})
  end

  def stub_search_and_fetch(versions_by_full_name)
    repositories = versions_by_full_name.map { |full_name, version|
      EndOfLife::Repository.new(
        full_name: full_name,
        url: "https://github.com/#{full_name}",
        files: [EndOfLife::InMemoryFile.new(".ruby-version", version)]
      )
    }

    allow(EndOfLife::Repository).to receive(:search).and_return(
      Dry::Monads::Success(versions_by_full_name.keys)
    )
    allow(EndOfLife::Repository).to receive(:fetch).and_return(
      Dry::Monads::Success(repositories)
    )
  end
end
