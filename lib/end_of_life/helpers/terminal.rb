require "pastel"
require "tty-spinner"
require "tty-table"

module EndOfLife
  module Helpers::Terminal
    def error_msg(message, label: "[ERROR]")
      label = paint.red("#{label} ")

      "#{label} #{message}"
    end

    def with_loading_spinner(message)
      result = nil

      new_spinner(message).run do |spinner|
        result = yield(spinner)
        spinner.success
      end

      result
    end

    def table(...)
      TTY::Table.new(...).render(:unicode, padding: [0, 1])
    end

    def paint
      @paint ||= Pastel.new
    end

    def new_spinner(message, options = {success_mark: paint.green("✔"), error_mark: paint.red("✖")})
      TTY::Spinner.new("[:spinner] #{message}", options)
    end
  end
end
