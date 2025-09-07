# frozen_string_literal: true

require "async"
require "dry-monads"
require "json"
require "base64"
require "octokit"
require "zeitwerk"

Zeitwerk::Loader.for_gem.tap { |it|
  it.inflector.inflect("cli" => "CLI", "api" => "API")
}.setup

module EndOfLife
  extend Product::Registry
  extend Helpers::Terminal

  scans_for :ruby, search_query: "language:ruby"
end
