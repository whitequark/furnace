module Furnace
  module Code
    class SurroundedToken < NonterminalToken
      def text_before
        ""
      end

      def text_after
        ""
      end

      def to_text
        "#{text_before}#{children.map(&:to_text).join}#{text_after}"
      end

      def to_structure(options={})
        structurize "#{text_before} ... #{text_after}", options
      end
    end
  end
end