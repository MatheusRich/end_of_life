# frozen_string_literal: true

if ENV["COVERAGE"]
  require "simplecov"

  SimpleCov.start do
    enable_coverage :branch
    add_filter "/spec/"
  end
end

require "end_of_life"
require "climate_control"
require "vcr"
require "webmock"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.filter_sensitive_data("REDACTED") { ENV["GITHUB_TOKEN"] }
end

RSpec::Matchers.define_negated_matcher :raise_no_error, :raise_error

module EndOfLife
  module TestHelpers
    def with_env(...)
      ClimateControl.modify(...)
    end

    def travel_to(date)
      date = Date.parse(date)

      allow(Date).to receive(:today).and_return(date)
    end

    def exit_with_code(code)
      raise_error(SystemExit) { |error| expect(error.status).to eq(code) }
    end

    def abort_with(message)
      raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
        expect(error.message).to match(message)
      end.and output(message).to_stderr
    end

    def replace_standard_streams(stdout: StringIO.new, stderr: StringIO.new)
      original_streams = [$stdout, $stderr]
      $stdout, $stderr = stdout, stderr
      yield
    ensure
      $stdout, $stderr = *original_streams
    end
  end
end

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

  config.around(:each, :vcr) do |example|
    VCR.use_cassette(example.metadata[:vcr]) do
      example.run
    end
  end

  config.include EndOfLife::TestHelpers
end
