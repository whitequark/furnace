module Furnace
  module Code
    class NewlineToken < TerminalToken
      def to_text
        "\n"
      end
    end
  end
end