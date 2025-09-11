# frozen_string_literal: true

require "ostruct"

RSpec.describe EndOfLife::Repository, vcr: "products-ruby" do
  describe "#using_eol?" do
    it "returns true if version is eol" do
      client = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => {content: "1.9.3"},
          ".tool-versions" => nil,
          "Gemfile" => nil,
          "Gemfile.lock" => nil,
          "mise.toml" => nil
        }
      )
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      expect(repo).to be_using_eol(EndOfLife::Product.find("ruby"))
    end

    it "returns false if version is not eol" do
      client = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => {content: "9999999"},
          ".tool-versions" => nil,
          "Gemfile" => nil,
          "Gemfile.lock" => nil,
          "mise.toml" => nil
        }
      )
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      expect(repo).not_to be_using_eol(EndOfLife::Product.find("ruby"))
    end

    it "accepts a custom date", :aggregate_failures do
      client = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => {content: "3.0.0"},
          ".tool-versions" => nil,
          "Gemfile" => nil,
          "Gemfile.lock" => nil,
          "mise.toml" => nil
        }
      )
      ruby_3_eol_date = Date.parse("2024-04-23")

      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      expect(repo.using_eol?(EndOfLife::Product.find("ruby"), at: ruby_3_eol_date)).to be true
      expect(repo.using_eol?(EndOfLife::Product.find("ruby"), at: ruby_3_eol_date.prev_day)).to be false
    end

    it "returns nil if version is nil" do
      client = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => nil,
          ".tool-versions" => nil,
          "Gemfile" => nil,
          "Gemfile.lock" => nil,
          "mise.toml" => nil
        }
      )
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      expect(repo.using_eol?(EndOfLife::Product.find("ruby"))).to be_nil
    end
  end

  describe "#search" do
    it "returns a success monad on successful API call" do
      with_env GITHUB_TOKEN: "something" do
        client = build_client
        allow(Octokit::Client).to receive(:new).and_return(client)
        result = EndOfLife::Repository.search({
          product: EndOfLife::Product.find("ruby")
        })

        expect(result).to be_success
      end
    end

    context "when GITHUB_TOKEN env is not set", :aggregate_failures do
      it "returns a failure monad" do
        with_env GITHUB_TOKEN: nil do
          result = EndOfLife::Repository.search({
            product: EndOfLife::Product.find("ruby")
          })

          expect(result).to be_failure
          expect(result.failure).to eq "Please set GITHUB_TOKEN environment variable"
        end
      end
    end

    it "calls the GitHub API once" do
      client = build_client
      allow(Octokit::Client).to receive(:new).and_return(client)

      with_env GITHUB_TOKEN: "FOO" do
        EndOfLife::Repository.search(
          product: EndOfLife::Product.find("ruby"),
          user: "thoughtbot",
          organizations: nil,
          repository: nil
        )
      end

      expect(client).to have_received(:search_repositories).once
    end

    it "returns the search results" do
      paperclip = OpenStruct.new(full_name: "thoughtbot/paperclip", language: "ruby")
      archived_repo = OpenStruct.new(full_name: "thoughtbot/archived-repo", language: "ruby", archived: true)
      client = build_client(
        search_results: [paperclip, archived_repo]
      )
      allow(Octokit::Client).to receive(:new).and_return(client)

      repositories = with_env GITHUB_TOKEN: "FOO" do
        EndOfLife::Repository.search(
          product: EndOfLife::Product.find("ruby"),
          user: "thoughtbot",
          skip_archived: true
        )
      end

      results = repositories.value!.map(&:full_name)
      expect(results).to eq [paperclip.full_name]
    end

    context "when not skipping archived repositories" do
      it "returns the search results" do
        paperclip = OpenStruct.new(full_name: "thoughtbot/paperclip", language: "ruby")
        archived_repo = OpenStruct.new(full_name: "thoughtbot/archived-repo", language: "ruby", archived: true)
        client = build_client(
          search_results: [paperclip, archived_repo]
        )
        allow(Octokit::Client).to receive(:new).and_return(client)

        repositories = with_env GITHUB_TOKEN: "FOO" do
          EndOfLife::Repository.search(
            product: EndOfLife::Product.find("ruby"),
            user: "thoughtbot",
            skip_archived: false
          )
        end

        results = repositories.value!.map(&:full_name)
        expect(results).to eq [paperclip.full_name, archived_repo.full_name]
      end
    end
  end

  describe "#min_release_of" do
    it "returns the minimum release of a product found in the repository" do
      client = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => {content: "2.6.3"},
          ".tool-versions" => {content: "ruby 2.5.0"},
          "Gemfile" => nil,
          "Gemfile.lock" => nil,
          "mise.toml" => nil
        }
      )
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      result = repo.min_release_of(EndOfLife::Product.find("ruby"))

      expect(result).to eq(EndOfLife::Product::Release.ruby("2.5.0"))
    end

    it "decodes base64 files" do
      client = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => {content: "2.6.3", encoding: "base64"},
          ".tool-versions" => nil,
          "Gemfile" => nil,
          "Gemfile.lock" => nil,
          "mise.toml" => nil
        }
      )
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      result = repo.min_release_of(EndOfLife::Product.find("ruby"))

      expect(result).to eq(EndOfLife::Product::Release.ruby("2.6.3"))
    end

    it "raises if file has unknown encoding" do
      client = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => {content: "2.6.3", encoding: "unknown_encoding"},
          ".tool-versions" => nil,
          "Gemfile" => nil,
          "Gemfile.lock" => nil,
          "mise.toml" => nil
        }
      )
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      expect { repo.min_release_of(EndOfLife::Product.find("ruby")) }.to raise_error(ArgumentError, 'Unsupported encoding: "unknown_encoding"')
    end

    it "returns nil if file doen't exist" do
      client = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => {content: Octokit::NotFound},
          ".tool-versions" => {content: Octokit::NotFound},
          "Gemfile" => {content: Octokit::NotFound},
          "Gemfile.lock" => {content: Octokit::NotFound},
          "mise.toml" => {content: Octokit::NotFound}
        }
      )
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      expect(repo.min_release_of(EndOfLife::Product.find("ruby"))).to be_nil
    end

    it "searches for version in .ruby-version" do
      client = double(:client, contents: nil)
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      repo.min_release_of(EndOfLife::Product.find("ruby"))

      expect(client).to have_received(:contents).with("thoughtbot/paperclip", path: ".ruby-version")
    end

    it "searches for version in Gemfile" do
      client = double(:client, contents: nil)
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      repo.min_release_of(EndOfLife::Product.find("ruby"))

      expect(client).to have_received(:contents).with("thoughtbot/paperclip", path: "Gemfile")
    end

    it "searches for version in Gemfile.lock" do
      client = double(:client, contents: nil)
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      repo.min_release_of(EndOfLife::Product.find("ruby"))

      expect(client).to have_received(:contents).with("thoughtbot/paperclip", path: "Gemfile.lock")
    end

    it "searches for version in .tool-versions" do
      client = double(:client, contents: nil)
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: client
      )

      repo.min_release_of(EndOfLife::Product.find("ruby"))

      expect(client).to have_received(:contents).with("thoughtbot/paperclip", path: ".tool-versions")
    end

    it "fetches files asynchronously" do
      seconds_of_sleep = 0.5
      sleepy_github = build_client(
        repo: "thoughtbot/paperclip",
        contents: {
          ".ruby-version" => {
            content: lambda {
              sleep(seconds_of_sleep)
              nil
            }
          },
          ".tool-versions" => {
            content: lambda {
              sleep(seconds_of_sleep)
              "ruby 2.5.0"
            }
          },
          "Gemfile" => {
            content: lambda {
              sleep(seconds_of_sleep)
              nil
            }
          },
          "Gemfile.lock" => {
            content: lambda {
              sleep(seconds_of_sleep)
              nil
            }
          },
          "mise.toml" => {content: lambda {
            sleep(seconds_of_sleep)
            nil
          }}
        }
      )
      repo = EndOfLife::Repository.new(
        full_name: "thoughtbot/paperclip",
        url: "https://github.com/thoughtbot/paperclip",
        github_client: sleepy_github
      )

      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      repo.min_release_of(EndOfLife::Product.find("ruby"))
      total_elapsed_time = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0

      overhead = 0.1
      expect(total_elapsed_time).to be_within(overhead).of(seconds_of_sleep)
    end
  end

  private

  def build_client(repo: nil, contents: [], search_results: [])
    client = Object.new

    response = OpenStruct.new(
      items: search_results,
      incomplete_results: false
    )
    allow(client).to receive(:search_repositories).and_return(response)
    allow(client).to receive(:auto_paginate=).with(true)
    allow(client).to receive(:user).and_return(OpenStruct.new(login: "test_user"))

    contents.each do |path, config|
      config ||= {}
      encoder = (config[:encoding] == "base64") ? Base64.method(:encode64) : ->(x) { x }

      if config[:content] == Octokit::NotFound
        allow(client).to receive(:contents).with(repo, path: path).and_raise(Octokit::NotFound)
      else
        allow(client).to receive(:contents).with(repo, path: path) do
          if config[:content]
            file_content = if config[:content].is_a?(Proc)
              config[:content].call
            else
              config[:content]
            end

            OpenStruct.new(
              content: encoder.call(file_content) || "",
              path: path,
              encoding: config[:encoding]
            )
          end
        end
      end
    end

    client
  end
end
