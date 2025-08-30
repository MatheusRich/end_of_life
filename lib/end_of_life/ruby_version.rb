require "net/http"
require "rubygems"

module EndOfLife
  module RubyVersion
    RUBY = Product.new("ruby")

    extend self

    def new(version, eol_date: nil)
      Product::Release.new(product: "ruby", version:, eol_date:)
    end

    def eol_versions_at(...) = RUBY.eol_releases_at(...)
    def latest_eol(...)      = RUBY.latest_eol(...)
  end
end
