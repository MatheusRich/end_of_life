# frozen_string_literal: true

require "ostruct"

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

    describe "#eol_ruby?" do
      it "returns true if version is eol" do
        client = build_client(
          repo: "thoughtbot/paperclip",
          contents: {
            ".ruby-version" => {content: "1.9.3"},
            ".tool-versions" => nil,
            "Gemfile" => nil,
            "Gemfile.lock" => nil
          }
        )
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        expect(repo).to be_eol_ruby
      end

      it "returns false if version is not eol" do
        client = build_client(
          repo: "thoughtbot/paperclip",
          contents: {
            ".ruby-version" => {content: "9999999"},
            ".tool-versions" => nil,
            "Gemfile" => nil,
            "Gemfile.lock" => nil
          }
        )
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        expect(repo).not_to be_eol_ruby
      end

      it "accepts a custom date", :aggregate_failures do
        client = build_client(
          repo: "thoughtbot/paperclip",
          contents: {
            ".ruby-version" => {content: "3.0.0"},
            ".tool-versions" => nil,
            "Gemfile" => nil,
            "Gemfile.lock" => nil
          }
        )
        ruby_3_eol_date = Date.parse("2024-03-31")
        day_before_of_ruby_3_eol_date = ruby_3_eol_date - 1

        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        expect(repo.eol_ruby?(at: ruby_3_eol_date)).to be true
        expect(repo.eol_ruby?(at: day_before_of_ruby_3_eol_date)).to be false
      end

      it "returns nil if version is nil" do
        client = build_client(
          repo: "thoughtbot/paperclip",
          contents: {
            ".ruby-version" => nil,
            ".tool-versions" => nil,
            "Gemfile" => nil,
            "Gemfile.lock" => nil
          }
        )
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        expect(repo.eol_ruby?).to be_nil
      end
    end

    describe "#fetch" do
      let(:client) { instance_double(Octokit::Client, :user => user) }
      let(:user) { OpenStruct.new(:login => "j-random-hacker") }

      before do
        allow(Octokit::Client).to receive(:new).and_return(client)
      end

      context "with complete results" do
        let(:items) { [OpenStruct.new(:full_name => "j-random-hacker/ruby-foo", :language => "ruby")] }
        let(:response) { OpenStruct.new(:items => items, incomplete_results: false) }

        subject(:repositories) do
          with_env GITHUB_TOKEN: "FOO" do
            EndOfLife::Repository.fetch(language: "ruby", user: "j-random-hacker", organizations: nil, repository: nil)
          end
        end

        before do
          allow(client).to receive(:auto_paginate=).with(true)
          allow(client).to receive(:user).and_return(user)
          allow(client).to receive(:search_repositories).and_return(response)
        end

        it "calls the GitHub API once" do
          repositories
          expect(client).to have_received(:search_repositories).once
        end

        it "returns Success with the collection of repositories" do
          expect(repositories.value_or(nil).count).to eq(1)
        end
      end
    end

    describe "#ruby_version" do
      it "returns the minimum ruby version found in the repository" do
        client = build_client(
          repo: "thoughtbot/paperclip",
          contents: {
            ".ruby-version" => {content: "2.6.3"},
            ".tool-versions" => {content: "ruby 2.5.0"},
            "Gemfile" => nil,
            "Gemfile.lock" => nil
          }
        )
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        result = repo.ruby_version

        expect(result).to eq(EndOfLife::RubyVersion.new("2.5.0"))
      end

      it "decodes base64 files" do
        client = build_client(
          repo: "thoughtbot/paperclip",
          contents: {
            ".ruby-version" => {content: "2.6.3", encoding: "base64"},
            ".tool-versions" => nil,
            "Gemfile" => nil,
            "Gemfile.lock" => nil
          }
        )
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        result = repo.ruby_version

        expect(result).to eq(EndOfLife::RubyVersion.new("2.6.3"))
      end

      it "raises if file has unknown encoding" do
        client = build_client(
          repo: "thoughtbot/paperclip",
          contents: {
            ".ruby-version" => {content: "2.6.3", encoding: "unknown_encoding"},
            ".tool-versions" => nil,
            "Gemfile" => nil,
            "Gemfile.lock" => nil
          }
        )
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        expect { repo.ruby_version }.to raise_error(ArgumentError, 'Unsupported encoding: "unknown_encoding"')
      end

      it "returns nil if file doen't exist" do
        client = build_client(
          repo: "thoughtbot/paperclip",
          contents: {
            ".ruby-version" => {content: Octokit::NotFound},
            ".tool-versions" => {content: Octokit::NotFound},
            "Gemfile" => {content: Octokit::NotFound},
            "Gemfile.lock" => {content: Octokit::NotFound}
          }
        )
        repo = EndOfLife::Repository.new(
          full_name: "thoughtbot/paperclip",
          url: "https://github.com/thoughtbot/paperclip",
          github_client: client
        )

        expect(repo.ruby_version).to be_nil
      end

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

    def build_client(repo:, contents:)
      client = Object.new

      contents.each do |path, config|
        config ||= {}
        encoder = config[:encoding] == "base64" ? Base64.method(:encode64) : ->(x) { x }

        if config[:content] == Octokit::NotFound
          allow(client).to receive(:contents).with(repo, path: path).and_raise(Octokit::NotFound)
        else
          allow(client).to receive(:contents).with(repo, path: path).and_return(
            if config[:content]
              OpenStruct.new(
                content: encoder.call(config[:content]),
                name: path,
                encoding: config[:encoding]
              )
            end
          )
        end
      end

      client
    end
  end
end
