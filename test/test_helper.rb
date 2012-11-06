$LOAD_PATH << File.expand_path('../../lib', __FILE__)

require 'furnace'
include Furnace

module Bacon
  module ColoredOutput
    def handle_specification(name)
      puts spaces + name
      yield
      puts if Counter[:context_depth] == 1
    end

    def handle_requirement(description)
      print spaces

      error = yield

      print error.empty? ? "\e[32m" : "\e[1;31m"
      print "  - #{description}"
      puts error.empty? ? "\e[0m" : " [#{error}]\e[0m"
    end

    def handle_summary
      print ErrorLog  if Backtraces
      puts "%d specifications (%d requirements), %d failures, %d errors" %
        Counter.values_at(:specifications, :requirements, :failed, :errors)
    end

    def spaces
      "  " * (Counter[:context_depth] - 1)
    end
  end

  extend ColoredOutput
end