require "bundler"

module EndOfLife
  module Helpers
    module SilentBundler
      extend self

      def silence_bundler
        previous_ui = Bundler.ui
        Bundler.ui = Bundler::UI::Silent.new

        yield
      ensure
        Bundler.ui = previous_ui
      end
    end
  end
end
