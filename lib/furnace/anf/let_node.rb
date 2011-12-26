module Furnace
  module ANF
    class LetNode < Node
      attr_reader :arguments

      def initialize(graph, arguments)
        super(graph)

        @arguments = arguments
      end

      def try_eliminate
        if identity?
          entering_edges.each do |edge|
            edge.target = leaving_edge.target
          end
        end
      end

      def identity?
        @arguments.reduce(true) { |r, (k, v)| r && (v === k) }
      end

      def try_propagate
      end

      def static?(node)
        [ NilClass, TrueClass, FalseClass, Fixnum, Symbol,
          AST::LocalVariable, AST::InstanceVariable ].include? node.class
      end

      def to_human_readable
        "let\n#{@arguments.map { |k, v| "  #{k} = #{humanize v}" }.join "\n"}"
      end
    end
  end
end