module EndOfLife
  module VersionDetectors
    module Rails
      extend VersionDetector

      detects_from "Gemfile.lock" do |file_content|
        gemfile_lock = Parsers::GemfileLock.parse(file_content) or next
        rails = gemfile_lock.specs.find { |it| it.name == "rails" } or next

        Product::Release.new(product: "rails", version: rails.version)
      end

      detects_from "Gemfile" do |file_content|
        gemfile = Parsers::Gemfile.parse(file_content) or next
        rails_dep = gemfile.dependencies.find { |it| it.name == "rails" } or next
        exact_version = rails_dep
          .requirement
          .requirements
          .filter { |op, _| op == "=" } # standard:disable Style/HashSlice
          .max_by { |_, version| version } or next

        Product::Release.new(product: "rails", version: exact_version.last)
      end
    end
  end
end
