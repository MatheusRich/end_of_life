module EndOfLife
  module Helpers::Time
    include Helpers::Text

    def relative_time_in_words(date)
      days_away = (date - Date.today).to_i
      return "today" if days_away.zero?

      duration = duration_in_words(days_away.abs)

      if days_away.positive?
        "in #{duration}"
      else
        "#{duration} ago"
      end
    end

    private

    def duration_in_words(number_of_days)
      if number_of_days >= 365
        years = (number_of_days / 365.0).floor
        pluralize(years, "year")
      elsif number_of_days >= 30
        months = (number_of_days / 30.0).floor
        pluralize(months, "month")
      elsif number_of_days >= 14
        weeks = (number_of_days / 7.0).floor
        pluralize(weeks, "week")
      else
        pluralize(number_of_days, "day")
      end
    end
  end
end
