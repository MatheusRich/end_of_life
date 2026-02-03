# frozen_string_literal: true

require "spec_helper"

RSpec.describe "end_of_life schedule", :capture_io, vcr: "products-ruby" do
  include EndOfLife::Helpers::Terminal

  subject(:cli) { EndOfLife::CLI.new }

  it "shows the EOL schedule for the given product", :aggregate_failures do
    travel_to "2025-09-30" do
      argv = "schedule ruby".split

      cli.call(argv)

      expect($stdout.string).to eq <<~OUTPUT
        ┌─────────────────┬───────────┬───────────────────────────┐
        │ Product Release │ Status    │ EOL Date                  │
        ├─────────────────┼───────────┼───────────────────────────┤
        │ ruby@3.4.5      │ Supported │ 2028-03-31 (in 2 years)   │
        │ ruby@3.3.9      │ Supported │ 2027-03-31 (in 1 year)    │
        │ ruby@3.2.9      │ Supported │ 2026-03-31 (in 6 months)  │
        │ ruby@3.1.7      │ EOL       │ 2025-03-31 (6 months ago) │
        │ ruby@3.0.7      │ EOL       │ 2024-04-23 (1 year ago)   │
        │ ruby@2.7.8      │ EOL       │ 2023-03-31 (2 years ago)  │
        │ ruby@2.6.10     │ EOL       │ 2022-03-31 (3 years ago)  │
        │ ruby@2.5.9      │ EOL       │ 2021-03-31 (4 years ago)  │
        │ ruby@2.4.10     │ EOL       │ 2020-03-31 (5 years ago)  │
        │ ruby@2.3.8      │ EOL       │ 2019-03-31 (6 years ago)  │
        │ ruby@2.2.10     │ EOL       │ 2018-03-31 (7 years ago)  │
        │ ruby@2.1.10     │ EOL       │ 2017-03-31 (8 years ago)  │
        │ ruby@2.0.0p648  │ EOL       │ 2016-02-24 (9 years ago)  │
        │ ruby@1.9.3p551  │ EOL       │ 2015-02-23 (10 years ago) │
        └─────────────────┴───────────┴───────────────────────────┘
      OUTPUT
      expect($stderr.string).to be_empty
    end
  end

  context "when the product is unknown" do
    it "shows an error message", :aggregate_failures do
      argv = "schedule unknown".split

      expect {
        cli.call(argv)
      }.to exit_with_code(1)

      expect($stderr.string).to include("Invalid argument: unknown")
      expect($stdout.string).to be_empty
    end
  end

  context "with missing arguments" do
    it "shows help message", :aggregate_failures do
      argv = ["schedule"]

      expect {
        cli.call(argv)
      }.to exit_with_code(1)

      expect($stderr.string).to include("Missing required argument: product")
      expect($stderr.string).to include("Usage:")
      expect($stdout.string).to be_empty
    end
  end
end
