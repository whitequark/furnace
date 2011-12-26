module Furnace
  module ANF
    class ReturnNode < Node
      attr_reader :result

      def initialize(graph, result)
        super(graph)

        @result = result
      end

      def to_human_readable
        "return\n#{humanize @result}"
      end
    end
  end
end