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

  describe "#search" do
    it "returns a success monad on successful API call" do
      with_env GITHUB_TOKEN: "something" do
        client = build_client
        allow(Octokit::Client).to receive(:new).and_return(client)

        result = EndOfLife::Repository.search({product: EndOfLife::Product.find("ruby")})

        expect(result).to be_success
      end
    end

    context "when GITHUB_TOKEN env is not set", :aggregate_failures do
      it "returns a failure monad" do
        with_env GITHUB_TOKEN: nil do
          result = EndOfLife::Repository.search({product: EndOfLife::Product.find("ruby")})

          expect(result).to be_failure
          expect(result.failure).to eq "Please set GITHUB_TOKEN environment variable"
        end
      end
    end

    it "does not fetch repositories when the code search finds nothing", :aggregate_failures do
      client = build_client
      allow(Octokit::Client).to receive(:new).and_return(client)

      search_with(client, user: "thoughtbot", organizations: nil, repository: nil)

      expect(client).to have_received(:search_code).once
      expect(client).not_to have_received(:post)
    end

    # Without this the scan reads the first page of code search results only.
    it "reads every page of the code search" do
      client = build_client
      allow(Octokit::Client).to receive(:new).and_return(client)

      search_with(client, user: "thoughtbot")

      expect(client).to have_received(:auto_paginate=).with(true)
    end

    it "returns the search results" do
      client = build_client(search_results: [repo_result("thoughtbot/paperclip"), repo_result("thoughtbot/archived", archived: true)])
      allow(Octokit::Client).to receive(:new).and_return(client)

      repositories = search_with(client, user: "thoughtbot", skip_archived: true)

      expect(repositories.value!.map(&:full_name)).to eq ["thoughtbot/paperclip"]
    end

    it "returns the url of each repository" do
      client = build_client(search_results: [repo_result("thoughtbot/paperclip")])
      allow(Octokit::Client).to receive(:new).and_return(client)

      repositories = search_with(client, user: "thoughtbot")

      expect(repositories.value!.first.url).to eq "https://github.com/thoughtbot/paperclip"
    end

    it "returns the version files for each repository" do
      client = build_client(
        search_results: [repo_result("thoughtbot/paperclip")],
        files: {"thoughtbot/paperclip" => {".ruby-version" => "2.5.0"}}
      )
      allow(Octokit::Client).to receive(:new).and_return(client)

      repositories = search_with(client, user: "thoughtbot")

      expect(repositories.value!.first.min_release_of(EndOfLife::Product.find("ruby")))
        .to eq(EndOfLife::Product::Release.ruby("2.5.0"))
    end

    # If the alias that asks for a file and the one that reads it disagree,
    # every file gets another file's content.
    it "gives each file the content of the path it asked for", :aggregate_failures do
      client = build_client(
        search_results: [repo_result("thoughtbot/paperclip")],
        files: {
          "thoughtbot/paperclip" => {
            ".ruby-version" => "3.1.0",
            ".tool-versions" => "ruby 2.5.0"
          }
        }
      )
      allow(Octokit::Client).to receive(:new).and_return(client)

      repository = search_with(client, user: "thoughtbot").value!.first

      expect(repository.files.map { |file| [file.path, file.read] })
        .to contain_exactly([".ruby-version", "3.1.0"], [".tool-versions", "ruby 2.5.0"])
      expect(repository.min_release_of(EndOfLife::Product.find("ruby")))
        .to eq(EndOfLife::Product::Release.ruby("2.5.0"))
    end

    # GraphQL cuts a blob over ~512 KB, and a Gemfile.lock holds RUBY VERSION
    # at the end, so the truncated text would hide the version.
    it "reads the whole file when GitHub truncates it", :aggregate_failures do
      whole_lockfile = "GEM\n  specs:\n\nRUBY VERSION\n   ruby 2.5.0p57\n"
      client = build_client(
        search_results: [repo_result("thoughtbot/paperclip")],
        files: {"thoughtbot/paperclip" => {"Gemfile.lock" => {text: "GEM\n  specs:\n", isTruncated: true}}},
        raw_files: {["thoughtbot/paperclip", "Gemfile.lock"] => whole_lockfile}
      )
      allow(Octokit::Client).to receive(:new).and_return(client)

      repository = search_with(client, user: "thoughtbot").value!.first

      expect(repository.files.map(&:read)).to eq [whole_lockfile]
      expect(repository.min_release_of(EndOfLife::Product.find("ruby")))
        .to eq(EndOfLife::Product::Release.ruby("2.5.0p57"))
    end

    it "drops a truncated file when the whole file cannot be read" do
      client = build_client(
        search_results: [repo_result("thoughtbot/paperclip")],
        files: {
          "thoughtbot/paperclip" => {
            "Gemfile.lock" => {text: "GEM\n", isTruncated: true},
            ".ruby-version" => "2.5.0"
          }
        }
      )
      allow(Octokit::Client).to receive(:new).and_return(client)

      repository = search_with(client, user: "thoughtbot").value!.first

      expect(repository.files.map(&:path)).to eq [".ruby-version"]
    end

    it "skips a repository that GitHub cannot read" do
      client = build_client(
        search_results: [repo_result("thoughtbot/paperclip"), repo_result("thoughtbot/gone")],
        unreadable: ["thoughtbot/gone"]
      )
      allow(Octokit::Client).to receive(:new).and_return(client)

      repositories = search_with(client, user: "thoughtbot")

      expect(repositories.value!.map(&:full_name)).to eq ["thoughtbot/paperclip"]
    end

    it "asks for every file the product detector knows about" do
      client = build_client(search_results: [repo_result("thoughtbot/paperclip")])
      allow(Octokit::Client).to receive(:new).and_return(client)

      search_with(client, user: "thoughtbot")

      query = JSON.parse(captured_graphql_bodies(client).first).fetch("query")
      expect(query).to include(*ruby_relevant_files.map { |file| "HEAD:#{file}" })
    end

    context "when not skipping archived repositories" do
      it "returns the search results" do
        client = build_client(search_results: [repo_result("thoughtbot/paperclip"), repo_result("thoughtbot/archived", archived: true)])
        allow(Octokit::Client).to receive(:new).and_return(client)

        repositories = search_with(client, user: "thoughtbot", skip_archived: false)

        expect(repositories.value!.map(&:full_name)).to eq ["thoughtbot/paperclip", "thoughtbot/archived"]
      end
    end

    # One request for every repository built a URL that GitHub rejects with a
    # 414 once an organization has a few hundred of them.
    it "splits large result sets into batches", :aggregate_failures do
      search_results = 60.times.map { |i| repo_result("thoughtbot/repo-#{i}") }
      client = build_client(search_results: search_results)
      allow(Octokit::Client).to receive(:new).and_return(client)

      repositories = search_with(client, user: "thoughtbot")

      expect(repositories.value!.size).to eq 60
      expect(captured_graphql_bodies(client).size).to eq 3
    end

    it "fetches batches concurrently" do
      seconds_of_sleep = 0.5
      search_results = 60.times.map { |i| repo_result("thoughtbot/repo-#{i}") }
      client = build_client(search_results: search_results, delay: seconds_of_sleep)
      allow(Octokit::Client).to receive(:new).and_return(client)
      EndOfLife::Product.find("ruby").all_releases # warm up, so the API call is not timed

      elapsed = time_of { search_with(client, user: "thoughtbot") }

      expect(elapsed).to be_within(0.2).of(seconds_of_sleep)
    end
  end

  private

  def search_with(_client, **options)
    with_env GITHUB_TOKEN: "FOO" do
      EndOfLife::Repository.search({product: EndOfLife::Product.find("ruby"), **options})
    end
  end

  def ruby_relevant_files
    EndOfLife::Product.find("ruby").version_detector.relevant_files
  end

  def build_repository(contents = {})
    EndOfLife::Repository.new(
      full_name: "thoughtbot/paperclip",
      url: "https://github.com/thoughtbot/paperclip",
      files: contents.map { |path, content| EndOfLife::InMemoryFile.new(path, content) }
    )
  end

  def repo_result(full_name, archived: false)
    OpenStruct.new(full_name: full_name, archived: archived)
  end

  def time_of
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
  end

  def captured_graphql_bodies(client)
    client.instance_variable_get(:@graphql_bodies)
  end

  def build_client(search_results: [], files: {}, delay: nil, unreadable: [], raw_files: {})
    client = Object.new
    client.instance_variable_set(:@graphql_bodies, [])

    code_search_response = OpenStruct.new(
      items: search_results.map { |result| OpenStruct.new(repository: OpenStruct.new(full_name: result.full_name)) }
    )
    allow(client).to receive(:search_code).and_return(code_search_response)
    allow(client).to receive(:auto_paginate=).with(true)
    allow(client).to receive(:user).and_return(OpenStruct.new(login: "test_user"))
    # The JSON media type answers with an empty body over 1 MB, so only the raw
    # one reads the whole file.
    allow(client).to receive(:contents) do |full_name, path:, accept: nil|
      raise Octokit::NotFound unless accept == "application/vnd.github.raw"

      raw_files.fetch([full_name, path]) { raise Octokit::NotFound }
    end
    allow(client).to receive(:post) do |_path, body|
      client.instance_variable_get(:@graphql_bodies) << body
      sleep(delay) if delay

      graphql_response_for(body, search_results, files, unreadable)
    end

    client
  end

  # Reads the aliases out of the query, so the test cannot assume the code
  # labels a file the way the test expects.
  def graphql_response_for(body, search_results, files, unreadable)
    query = JSON.parse(body).fetch("query")
    batch = search_results.select { |result| query.include?(%(name: "#{result.full_name.split("/", 2).last}")) }
    aliases = query.scan(/(\w+): object\(expression: "HEAD:(.+?)"\)/)

    data = batch.each_with_index.to_h { |result, index|
      next [:"repository#{index}", nil] if unreadable.include?(result.full_name)

      repository_files = files.fetch(result.full_name, {})
      blobs = aliases.to_h { |name, path| [name.to_sym, blob_for(repository_files[path])] }

      [
        :"repository#{index}",
        {
          nameWithOwner: result.full_name,
          url: "https://github.com/#{result.full_name}",
          isArchived: result.archived
        }.merge(blobs)
      ]
    }

    {data: data, errors: unreadable.any? ? [{type: "NOT_FOUND", message: "Could not resolve to a Repository"}] : nil}
  end

  def blob_for(content)
    return if content.nil?

    content.is_a?(Hash) ? content : {text: content}
  end
end
