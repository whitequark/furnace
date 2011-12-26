module Furnace
  module ANF
    class IfNode < Node
      attr_reader :condition

      def initialize(graph, condition)
        super(graph)

        @condition = condition
      end

      def to_human_readable
        "if\n#{humanize @condition}"
      end
    end
  end
end