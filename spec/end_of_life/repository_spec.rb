# frozen_string_literal: true

require "climate_control"

RSpec.describe EndOfLife::Repository do
  describe ".github_client" do
    it "returns a success monad with the client object" do
      with_env GITHUB_TOKEN: "something" do
        result = EndOfLife::Repository.github_client

        expect(result.value!).to be_a Octokit::Client
        expect(result).to be_success
      end
    end

    context "when GITHUB_TOKEN env is not set", :aggregate_failures do
      it "returns a failure monad" do
        with_env GITHUB_TOKEN: nil do
          pp ENV["GITHUB_TOKEN"]
          result = EndOfLife::Repository.github_client

          expect(result).to be_failure
          expect(result.failure).to eq "Please set GITHUB_TOKEN environment variable"
        end
      end
    end

    describe "#ruby_version" do
      it "searches for version in .ruby-version" do
        client = double(:client, contents: nil)
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        repo.ruby_version

        expect(client).to have_received(:contents).with("thoughtbot/paperclip", path: ".ruby-version")
      end

      it "searches for version in Gemfile" do
        client = double(:client, contents: nil)
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        repo.ruby_version

        expect(client).to have_received(:contents).with("thoughtbot/paperclip", path: "Gemfile")
      end

      it "searches for version in Gemfile.lock" do
        client = double(:client, contents: nil)
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        repo.ruby_version

        expect(client).to have_received(:contents).with("thoughtbot/paperclip", path: "Gemfile.lock")
      end

      it "searches for version in .tool-versions" do
        client = double(:client, contents: nil)
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        repo.ruby_version

        expect(client).to have_received(:contents).with("thoughtbot/paperclip", path: ".tool-versions")
      end
    end

    private

    def with_env(...)
      ClimateControl.modify(...)
    end
  end
end
