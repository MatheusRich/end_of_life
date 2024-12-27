# frozen_string_literal: true

require "async"
require "dry-monads"
require "json"
require "base64"
require "octokit"
require_relative "end_of_life/options"
require_relative "end_of_life/repository"
require_relative "end_of_life/ruby_version"
require_relative "end_of_life/terminal_helper"
require_relative "end_of_life/version"
require_relative "end_of_life/cli"

module EndOfLife
  extend TerminalHelper
end
