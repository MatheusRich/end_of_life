module EndOfLife
  module VersionDetectors
    module Python
      extend VersionDetector

      detects_from ".python-version" do |file_content|
        string_version = Gem::Version.new(file_content.strip)

        Product::Release.new(product: "python", version: string_version)
      rescue ArgumentError
        nil
      end

      detects_from ".tool-versions" do |file_content|
        tool_versions = Parsers::ToolVersions.parse(file_content)
        version = tool_versions["python"] or next

        Product::Release.new(product: "python", version:)
      end

      detects_from "mise.toml" do |file_content|
        tools = Parsers::MiseToml.parse(file_content) or next
        version = tools["python"] or next

        Product::Release.new(product: "python", version:)
      end
    end
  end
end
