module Furnace
  module Code
    class NonterminalToken < Token
      attr_reader :children

      def initialize(origin, children, options={})
        super(origin, options)
        @children = children.compact
      end

      def to_text
        children.map(&:to_text).join
      end
    end
  end
end