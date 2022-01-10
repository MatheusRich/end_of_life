require "pastel"
require "tty-link"
require "tty-spinner"
require "tty-table"

module EolRuby
  module TerminalHelper
    def exit_with_error!(message, label: "[ERROR]")
      label = paint.red("#{label} ")

      exit_with!("#{label} #{message}")
    end

    def exit_with!(message)
      raise Exit, message
    end

    def with_loading_spinner(message)
      result = nil

      EolRuby.listen_for_exit do
        new_spinner(message).run do |spinner|
          result = yield(spinner)
          spinner.success
        end
      end

      result
    end

    def link_to(text, href)
      TTY::Link.link_to(text, href)
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
