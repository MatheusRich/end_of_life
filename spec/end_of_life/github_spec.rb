# frozen_string_literal: true

require "octokit"

RSpec.describe EndOfLife::GitHub do
  # Octokit retries the idempotent methods only, and it waits no time between
  # the tries. The GraphQL fetch is a POST, so a 502 ended the whole batch.
  it "retries a failed POST after a pause", :aggregate_failures do
    attempts = 0
    connection = connection_with_stubbed_adapter do |stub|
      stub.post("/graphql") do
        attempts += 1
        (attempts == 1) ? [502, {}, ""] : [200, {"content-type" => "application/json"}, "{}"]
      end
    end

    elapsed = time_of { connection.post("/graphql", "{}") }

    expect(attempts).to eq 2
    expect(elapsed).to be > 0.1
  end

  it "leaves the middleware stack of Octokit alone" do
    described_class.send(:middleware)

    expect(retry_options_of(Octokit::Default::MIDDLEWARE).methods).not_to include :post
  end

  private

  def connection_with_stubbed_adapter(&stubs)
    stack = described_class.send(:middleware)
    stack.adapter(:test, &stubs)

    Faraday.new("https://api.github.com", builder: stack)
  end

  def retry_options_of(stack)
    handler = stack.handlers.find { |it| it.klass == Faraday::Retry::Middleware }

    Faraday::Retry::Middleware::Options.from(handler.instance_variable_get(:@args).first)
  end
end
