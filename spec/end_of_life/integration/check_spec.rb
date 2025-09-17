# frozen_string_literal: true

require "spec_helper"

RSpec.describe "end_of_life check", vcr: "products-ruby" do
  include EndOfLife::Helpers::Terminal

  subject(:cli) { EndOfLife::CLI.new }

  # TTY::Screen doesn't work with StringIO so I have to use this hack to test
  # the output of the command
  around(:each) do |example|
    io_thing = Class.new(StringIO) do
      def ioctl(*) = 0
    end

    replace_standard_streams(stdout: io_thing.new, stderr: io_thing.new) { example.run }
  end

  it "shows if the given product version is EOL", :aggregate_failures do
    argv = "check ruby@3.0.0".split

    expect {
      cli.call(argv)
    }.to exit_with_code(1)

    expect($stdout.string).to eq <<~OUTPUT
      ┌─────────────────┬────────┬─────────────────────────┐
      │ Product Release │ Status │ EOL Date                │
      ├─────────────────┼────────┼─────────────────────────┤
      │ ruby@3.0.7      │ EOL    │ 2024-04-23 (1 year ago) │
      └─────────────────┴────────┴─────────────────────────┘
    OUTPUT
    expect($stderr.string).to be_empty
  end

  context "when the product version is supported" do
    it "shows that the product version is supported", :aggregate_failures do
      argv = "check ruby@3".split

      cli.call(argv)

      expect($stdout.string).to eq <<~OUTPUT
        ┌─────────────────┬───────────┬─────────────────────────┐
        │ Product Release │ Status    │ EOL Date                │
        ├─────────────────┼───────────┼─────────────────────────┤
        │ ruby@3.4.5      │ Supported │ 2028-03-31 (in 2 years) │
        └─────────────────┴───────────┴─────────────────────────┘
      OUTPUT
      expect($stderr.string).to be_empty
    end
  end

  context "with multiple products", vcr: "products-nodejs-ruby" do
    it "shows the report for all of them in a single table", :aggregate_failures do
      argv = "check nodejs@18 ruby@3".split

      expect {
        cli.call(argv)
      }.to exit_with_code(1)

      expect($stdout.string).to eq <<~OUTPUT
        ┌─────────────────┬───────────┬───────────────────────────┐
        │ Product Release │ Status    │ EOL Date                  │
        ├─────────────────┼───────────┼───────────────────────────┤
        │ nodejs@18.20.8  │ EOL       │ 2025-04-30 (4 months ago) │
        │ ruby@3.4.5      │ Supported │ 2028-03-31 (in 2 years)   │
        └─────────────────┴───────────┴───────────────────────────┘
      OUTPUT
      expect($stderr.string).to be_empty
    end
  end

  context "with --max-eol-days-away option" do
    it "shows if the given product version is near EOL" do
      argv = "check ruby@3.2 --max-eol-days-away 365".split

      expect {
        cli.call(argv)
      }.to exit_with_code(1)

      expect($stdout.string).to eq <<~OUTPUT
        ┌─────────────────┬──────────┬──────────────────────────┐
        │ Product Release │ Status   │ EOL Date                 │
        ├─────────────────┼──────────┼──────────────────────────┤
        │ ruby@3.2.9      │ Near EOL │ 2026-03-31 (in 6 months) │
        └─────────────────┴──────────┴──────────────────────────┘
      OUTPUT
      expect($stderr.string).to be_empty
    end
  end

  context "when the product version is invalid", :aggregate_failures do
    it "shows an error message" do
      argv = "check ruby@lol".split

      expect {
        cli.call(argv)
      }.to exit_with_code(1)

      expect($stderr.string).to include("Malformed version number string: lol")
      expect($stdout.string).to be_empty
    end
  end

  context "when the product version is missing" do
    it "shows an error message", :aggregate_failures do
      argv = "check ruby".split

      expect {
        cli.call(argv)
      }.to exit_with_code(1)

      expect($stderr.string).to include("Invalid argument: ruby")
      expect($stdout.string).to be_empty
    end
  end

  context "when the product is unknown", :aggregate_failures do
    it "shows an error message" do
      argv = "check unknown@1.0".split

      expect {
        cli.call(argv)
      }.to exit_with_code(1)

      expect($stderr.string).to include("Invalid argument: unknown@1.0")
      expect($stdout.string).to be_empty
    end
  end

  context "with missing arguments" do
    it "shows help message", :aggregate_failures do
      argv = ["check"]

      expect {
        cli.call(argv)
      }.to exit_with_code(1)

      expect($stderr.string).to include("Expected at least 1 argument")
      expect($stderr.string).to include("Usage:")
      expect($stdout.string).to be_empty
    end
  end
end
