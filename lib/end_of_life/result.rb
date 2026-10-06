module EndOfLife
  module Result
    Success = Data.define(:value) do
      def successful? = true

      def failed? = false

      def on_success = yield(value)

      def on_failure = self

      def error = nil
    end

    Failure = Data.define(:error) do
      def successful? = false

      def failed? = true

      def on_success = self

      def on_failure = yield(error)

      def value = raise "No value for failed result"
    end
  end
end
