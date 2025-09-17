# frozen_string_literal: true

require "zeitwerk"

Zeitwerk::Loader.for_gem.tap { |it|
  it.inflector.inflect("cli" => "CLI", "api" => "API")
}.setup

module EndOfLife
  extend Product::Registry
  extend Helpers::Terminal

  scans_for :ruby
  scans_for :rails
  scans_for :nodejs, label: "Node.js"
end
