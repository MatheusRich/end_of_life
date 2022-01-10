require "dry-monads"

module Dry
  module Monads
    class Result
      class Success
        def on_success
          yield(self)

          self
        end

        def on_failure
          self
        end
      end

      class Failure
        def on_success
          self
        end

        def on_failure
          yield(self)

          self
        end
      end
    end
  end
end
