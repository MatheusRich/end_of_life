# frozen_string_literal: true

require "octokit"
require "ostruct"

RSpec.describe EndOfLife::Repository, vcr: "products-ruby" do
  describe "#using_eol?" do
    it "returns true if version is eol" do
      repo = build_repository(".ruby-version" => "1.9.3")

      expect(repo).to be_using_eol(EndOfLife::Product.find("ruby"))
    end

    it "returns false if version is not eol" do
      repo = build_repository(".ruby-version" => "9999999")

      expect(repo).not_to be_using_eol(EndOfLife::Product.find("ruby"))
    end

    it "accepts a custom date", :aggregate_failures do
      repo = build_repository(".ruby-version" => "3.0.0")
      ruby_3_eol_date = Date.parse("2024-04-23")

      expect(repo.using_eol?(EndOfLife::Product.find("ruby"), at: ruby_3_eol_date)).to be true
      expect(repo.using_eol?(EndOfLife::Product.find("ruby"), at: ruby_3_eol_date.prev_day)).to be false
    end

    it "returns nil if the repository has no version files" do
      repo = build_repository

      expect(repo.using_eol?(EndOfLife::Product.find("ruby"))).to be_nil
    end
  end

  describe "#min_release_of" do
    it "returns the minimum release of a product found in the repository" do
      repo = build_repository(
        ".ruby-version" => "2.6.3",
        ".tool-versions" => "ruby 2.5.0"
      )

      result = repo.min_release_of(EndOfLife::Product.find("ruby"))

      expect(result).to eq(EndOfLife::Product::Release.ruby("2.5.0"))
    end

    it "ignores empty files" do
      repo = build_repository(".ruby-version" => "", ".tool-versions" => "ruby 2.5.0")

      result = repo.min_release_of(EndOfLife::Product.find("ruby"))

      expect(result).to eq(EndOfLife::Product::Release.ruby("2.5.0"))
    end

    it "returns nil if the repository has no version files" do
      expect(build_repository.min_release_of(EndOfLife::Product.find("ruby"))).to be_nil
    end
  end

  describe ".search" do
    it "returns the full name of each repository the code search finds" do
      stub_github_client(found: ["thoughtbot/paperclip", "thoughtbot/clearance"])

      result = search_with(user: "thoughtbot")

      expect(result.value!).to eq ["thoughtbot/paperclip", "thoughtbot/clearance"]
    end

    it "returns no names when the code search finds nothing" do
      stub_github_client

      result = search_with(user: "thoughtbot", organizations: nil, repository: nil)

      expect(result.value!).to be_empty
    end

    it "fails when GITHUB_TOKEN is not set", :aggregate_failures do
      with_env GITHUB_TOKEN: nil do
        result = EndOfLife::Repository.search({product: EndOfLife::Product.find("ruby")})

        expect(result).to be_failure
        expect(result.failure).to eq "Please set GITHUB_TOKEN environment variable"
      end
    end

    # Without this the scan reads the first page of code search results only.
    it "reads every page of the code search" do
      client = stub_github_client

      search_with(user: "thoughtbot")

      expect(client).to have_received(:auto_paginate=).with(true)
    end
  end

  describe ".fetch" do
    it "fails when GITHUB_TOKEN is not set" do
      with_env GITHUB_TOKEN: nil do
        result = EndOfLife::Repository.fetch(["thoughtbot/paperclip"], {product: EndOfLife::Product.find("ruby")})

        expect(result).to be_failure
      end
    end

    it "skips archived repositories" do
      stub_github_client(archived: ["thoughtbot/archived"])

      result = fetch_with(["thoughtbot/paperclip", "thoughtbot/archived"], skip_archived: true)

      expect(result.value!.map(&:full_name)).to eq ["thoughtbot/paperclip"]
    end

    it "keeps only public repositories when asked to" do
      stub_github_client(private_repos: ["thoughtbot/secret"])

      result = fetch_with(["thoughtbot/paperclip", "thoughtbot/secret"], visibility: :public)

      expect(result.value!.map(&:full_name)).to eq ["thoughtbot/paperclip"]
    end

    it "keeps only private repositories when asked to" do
      stub_github_client(private_repos: ["thoughtbot/secret"])

      result = fetch_with(["thoughtbot/paperclip", "thoughtbot/secret"], visibility: :private)

      expect(result.value!.map(&:full_name)).to eq ["thoughtbot/secret"]
    end

    it "keeps archived repositories when asked to" do
      stub_github_client(archived: ["thoughtbot/archived"])

      result = fetch_with(["thoughtbot/paperclip", "thoughtbot/archived"], skip_archived: false)

      expect(result.value!.map(&:full_name)).to eq ["thoughtbot/paperclip", "thoughtbot/archived"]
    end

    it "returns the url of each repository" do
      stub_github_client

      result = fetch_with(["thoughtbot/paperclip"])

      expect(result.value!.first.url).to eq "https://github.com/thoughtbot/paperclip"
    end

    # If the alias that asks for a file and the one that reads it disagree,
    # every file gets another file's content.
    it "gives each file the content of the path it asked for", :aggregate_failures do
      stub_github_client(
        files: {
          "thoughtbot/paperclip" => {
            ".ruby-version" => "3.1.0",
            ".tool-versions" => "ruby 2.5.0"
          }
        }
      )

      repository = fetch_with(["thoughtbot/paperclip"]).value!.first

      expect(repository.files.map { |file| [file.path, file.read] })
        .to contain_exactly([".ruby-version", "3.1.0"], [".tool-versions", "ruby 2.5.0"])
      expect(repository.min_release_of(EndOfLife::Product.find("ruby")))
        .to eq(EndOfLife::Product::Release.ruby("2.5.0"))
    end

    # GraphQL cuts a blob over ~512 KB, and a Gemfile.lock holds RUBY VERSION
    # at the end, so the truncated text would hide the version.
    it "reads the whole file when GitHub truncates it", :aggregate_failures do
      whole_lockfile = "GEM\n  specs:\n\nRUBY VERSION\n   ruby 2.5.0p57\n"
      stub_github_client(
        files: {"thoughtbot/paperclip" => {"Gemfile.lock" => {text: "GEM\n  specs:\n", isTruncated: true}}},
        raw_files: {["thoughtbot/paperclip", "Gemfile.lock"] => whole_lockfile}
      )

      repository = fetch_with(["thoughtbot/paperclip"]).value!.first

      expect(repository.files.map(&:read)).to eq [whole_lockfile]
      expect(repository.min_release_of(EndOfLife::Product.find("ruby")))
        .to eq(EndOfLife::Product::Release.ruby("2.5.0p57"))
    end

    it "drops a truncated file when the whole file cannot be read" do
      stub_github_client(
        files: {
          "thoughtbot/paperclip" => {
            "Gemfile.lock" => {text: "GEM\n", isTruncated: true},
            ".ruby-version" => "2.5.0"
          }
        }
      )

      repository = fetch_with(["thoughtbot/paperclip"]).value!.first

      expect(repository.files.map(&:path)).to eq [".ruby-version"]
    end

    it "skips a repository that GitHub cannot read" do
      stub_github_client(unreadable: ["thoughtbot/gone"])

      result = fetch_with(["thoughtbot/paperclip", "thoughtbot/gone"])

      expect(result.value!.map(&:full_name)).to eq ["thoughtbot/paperclip"]
    end

    it "asks for every file the product detector knows about" do
      stub_github_client

      fetch_with(["thoughtbot/paperclip"])

      expect(graphql_queries.first).to include(*ruby_relevant_files.map { |file| "HEAD:#{file}" })
    end

    # One request for every repository built a URL that GitHub rejects with a
    # 414 once an organization has a few hundred of them.
    it "splits large result sets into batches", :aggregate_failures do
      stub_github_client

      result = fetch_with(60.times.map { |i| "thoughtbot/repo-#{i}" })

      expect(result.value!.size).to eq 60
      expect(graphql_queries.size).to eq 3
    end

    it "fetches batches concurrently" do
      seconds_of_sleep = 0.5
      stub_github_client(delay: seconds_of_sleep)
      EndOfLife::Product.find("ruby").all_releases # warm up, so the API call is not timed

      elapsed = time_of { fetch_with(60.times.map { |i| "thoughtbot/repo-#{i}" }) }

      expect(elapsed).to be_within(0.2).of(seconds_of_sleep)
    end
  end

  private

  def ruby_relevant_files
    EndOfLife::Product.find("ruby").version_detector.relevant_files
  end

  def search_with(**options)
    with_env GITHUB_TOKEN: "FOO" do
      EndOfLife::Repository.search({product: EndOfLife::Product.find("ruby"), **options})
    end
  end

  def fetch_with(full_names, **options)
    with_env GITHUB_TOKEN: "FOO" do
      EndOfLife::Repository.fetch(full_names, {product: EndOfLife::Product.find("ruby"), **options})
    end
  end

  def build_repository(contents = {})
    EndOfLife::Repository.new(
      full_name: "thoughtbot/paperclip",
      url: "https://github.com/thoughtbot/paperclip",
      files: contents.map { |path, content| EndOfLife::InMemoryFile.new(path, content) }
    )
  end

  def time_of
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  end

  attr_reader :graphql_queries

  def stub_github_client(found: [], files: {}, archived: [], private_repos: [], unreadable: [], raw_files: {}, delay: nil)
    @graphql_queries = []
    client = Object.new

    allow(client).to receive(:search_code).and_return(
      OpenStruct.new(items: found.map { |name| OpenStruct.new(repository: OpenStruct.new(full_name: name)) })
    )
    allow(client).to receive(:auto_paginate=).with(true)
    allow(client).to receive(:user).and_return(OpenStruct.new(login: "test_user"))
    # The JSON media type answers with an empty body over 1 MB, so only the raw
    # one reads the whole file.
    allow(client).to receive(:contents) do |full_name, path:, accept: nil|
      raise Octokit::NotFound unless accept == "application/vnd.github.raw"

      raw_files.fetch([full_name, path]) { raise Octokit::NotFound }
    end
    allow(client).to receive(:post) do |_path, body|
      query = JSON.parse(body).fetch("query")
      @graphql_queries << query
      sleep(delay) if delay

      graphql_response_for(query, files, archived, private_repos, unreadable)
    end
    allow(Octokit::Client).to receive(:new).and_return(client)

    client
  end

  # Reads the repositories and the file aliases out of the query, so the test
  # cannot assume the code labels them the way the test expects.
  def graphql_response_for(query, files, archived, private_repos, unreadable)
    full_names = query.scan(/repository\(owner: "(.+?)", name: "(.+?)"\)/).map { |owner, name| "#{owner}/#{name}" }
    aliases = query.scan(/(\w+): object\(expression: "HEAD:(.+?)"\)/)

    data = full_names.each_with_index.to_h { |full_name, index|
      next [:"repository#{index}", nil] if unreadable.include?(full_name)

      blobs = aliases.to_h { |name, path| [name.to_sym, blob_for(files.dig(full_name, path))] }

      [
        :"repository#{index}",
        metadata_for(full_name, archived, private_repos)
          .select { |field, _| query.match?(/^\s*#{field}\s*$/) }
          .merge(blobs)
      ]
    }

    {data: data, errors: unreadable.any? ? [{type: "NOT_FOUND", message: "Could not resolve to a Repository"}] : nil}
  end

  # Answers only the fields the query asks for, so a field the code stops
  # requesting cannot keep working by accident.
  def metadata_for(full_name, archived, private_repos)
    {
      nameWithOwner: full_name,
      url: "https://github.com/#{full_name}",
      isArchived: archived.include?(full_name),
      isPrivate: private_repos.include?(full_name)
    }
  end

  def blob_for(content)
    return if content.nil?

    content.is_a?(Hash) ? content : {text: content}
  end
end
