# frozen_string_literal: true

require_relative "lib/end_of_life/version"

Gem::Specification.new do |spec|
  spec.name = "end_of_life"
  spec.version = EndOfLife::VERSION
  spec.authors = ["Matheus Richard"]
  spec.email = ["matheusrichardt@gmail.com"]

  spec.summary = "Lists repositories using end-of-life software"
  spec.description = <<~TEXT
    Searches your GitHub repositores and lists the ones using end-of-life, i.e.
    unmaintained, software.
  TEXT
  spec.homepage = "https://github.com/MatheusRich/end_of_life"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # spec.metadata["allowed_push_host"] = "TODO: Set to your gem server 'https://example.com'"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:test|spec|features)/|\.(?:git|travis|circleci)|appveyor)})
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "async"
  spec.add_dependency "dry-monads", "~> 1.3"
  spec.add_dependency "octokit", "~> 9.0"
  spec.add_dependency "pastel", "~> 0.8.0"
  spec.add_dependency "tty-spinner", "~> 0.9.0"
  spec.add_dependency "tty-table", "~> 0.12.0"
  spec.add_dependency "zeitwerk", "~> 2.7"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
