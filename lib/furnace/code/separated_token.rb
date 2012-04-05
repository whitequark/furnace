module Furnace
  module Code
    class SeparatedToken < NonterminalToken
      def text_between
        ""
      end

      def to_text
        "#{text_before}#{children.map(&:to_text).join(text_between)}#{text_after}"
      end

      def to_structure(options={})
        structurize "#{text_before} #{([text_between] * 3).join(" ")} #{text_after}", options
      end
    end
  end
end