module EndOfLife
  module Helpers::Text
    def pluralize(count, singular, plural = nil)
      if count == 1
        "#{count} #{singular}"
      else
        "#{count} #{plural || "#{singular}s"}"
      end
    end
  end
end
