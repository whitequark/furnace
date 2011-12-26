module Furnace
  module ANF
    class InNode < Node
      attr_reader :expressions

      def initialize(graph, expressions)
        super(graph)

        @expressions = expressions
      end

      def to_human_readable
        "in\n#{@expressions.map { |e| "#{e.to_sexp(1)}" }.join "\n"}"
      end
    end
  end
end