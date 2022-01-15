# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start do
    enable_coverage :branch
    add_filter "/spec/"
  end
end

require "eol_ruby"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  if ENV["CI"]
    config.before(:example, :focus) { |example| raise "Focused spec found at #{example.location}" }
  else
    config.filter_run_when_matching :focus
  end
end
