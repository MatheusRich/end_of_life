require "async"
require "async/semaphore"
require "json"

module EndOfLife
  class Repository
    class Fetcher
      BATCH_SIZE = 25
      RAW_CONTENT = "application/vnd.github.raw"
      MAX_CONCURRENT_BATCHES = 10

      def initialize(github_client:, product:, skip_archived:)
        @github_client = github_client
        @product = product
        @skip_archived = skip_archived
      end

      def call(full_names)
        Sync do
          semaphore = Async::Semaphore.new(MAX_CONCURRENT_BATCHES)

          full_names
            .each_slice(BATCH_SIZE)
            .map { |batch| semaphore.async { fetch(batch) } }
            .flat_map(&:wait)
        end
      end

      private

      attr_reader :github_client, :product, :skip_archived

      def fetch(full_names)
        response = github_client.post("/graphql", {query: query_for(full_names)}.to_json)

        repositories_in(response).filter_map { |repository| build(repository) }
      end

      # GitHub sends a null entry for a repository it cannot read, such as one
      # deleted after the code search. The rest of the batch is still valid.
      def repositories_in(response)
        body = response.to_h
        data = body[:data]

        raise error_in(body) if data.nil?

        data.to_h.values.compact
      end

      def error_in(body)
        first_error = body[:errors]&.first

        first_error&.[](:message) || "GitHub returned no data for this batch of repositories"
      end

      def build(repository)
        return if skip_archived && repository[:isArchived]

        Repository.new(
          full_name: repository[:nameWithOwner],
          url: repository[:url],
          files: files_in(repository)
        )
      end

      def files_in(repository)
        file_aliases.filter_map do |name, path|
          blob = repository[name] or next

          content = if blob[:isTruncated]
            whole_file(repository[:nameWithOwner], path) or next
          else
            blob[:text].to_s
          end

          InMemoryFile.new(path, content)
        end
      end

      # GraphQL cuts a blob over ~512 KB, and a Gemfile.lock holds its RUBY
      # VERSION stanza at the end. The raw media type reads the whole file,
      # which the JSON one leaves empty over 1 MB.
      def whole_file(full_name, path)
        github_client.contents(full_name, path: path, accept: RAW_CONTENT).to_s
      rescue Octokit::Error
        nil
      end

      def file_aliases
        @file_aliases ||= product
          .version_detector
          .relevant_files
          .each_with_index
          .to_h { |path, index| [:"file#{index}", path] }
      end

      def query_for(full_names)
        repositories = full_names.each_with_index.map { |full_name, index|
          owner, name = full_name.split("/", 2)

          <<~GRAPHQL
            repository#{index}: repository(owner: #{owner.to_json}, name: #{name.to_json}) {
              nameWithOwner
              url
              isArchived
            #{file_fields}
            }
          GRAPHQL
        }

        "query {\n#{repositories.join}}"
      end

      def file_fields
        @file_fields ||= file_aliases.map { |name, path|
          "  #{name}: object(expression: #{"HEAD:#{path}".to_json}) { ... on Blob { isTruncated text } }"
        }.join("\n")
      end
    end
  end
end
