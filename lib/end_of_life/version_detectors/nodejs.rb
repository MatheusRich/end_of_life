require "bundler"

module EndOfLife
  module VersionDetectors
    module Nodejs
      extend VersionDetector

      detects_from ".node-version", ".nvmrc" do |file_content|
        string_version = Gem::Version.new(file_content.strip.delete_prefix("v"))

        Product::Release.new(product: "nodejs", version: string_version)
      rescue ArgumentError
        nil
      end

      detects_from ".tool-versions" do |file_content|
        tool_versions = Parsers::ToolVersions.parse(file_content)
        version = tool_versions["nodejs"] or next

        Product::Release.new(product: "nodejs", version:)
      end

      detects_from "mise.toml" do |file_content|
        tools = Parsers::MiseToml.parse(file_content) or next
        version = tools["node"] or next

        Product::Release.new(product: "nodejs", version:)
      end
    end
  end
end
