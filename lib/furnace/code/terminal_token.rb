module Furnace
  module Code
    class TerminalToken < Token
      def to_structure(options={})
        structurize to_text, options
      end
    end
  end
end