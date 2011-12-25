module Furnace
  module ANF
    def static?(node)
      [ NilClass, TrueClass, FalseClass, Fixnum, Symbol ].include? node.class
    end

    class Node
      attr_reader :graph, :astlet, :label

      def initialize(graph, astlet, label=nil)
        @graph, @astlet, @label = graph, astlet, label
      end
    end

    class ApplyNode < Node
      def target
        @graph.find(@astlet.children[0])
      end

      def arguments
        @astlet.children[1..-1]
      end

      def constant?
        @astlet.children.all? { |c| ANF.static? c }
      end

      def terminal?
        false
      end
    end

    class IfNode < Node
      def initialize(graph, astlet, label)
        super

        @true_expr  = ApplyNode.new(graph, astlet.children[1])
        @false_expr = ApplyNode.new(graph, astlet.children[2])
      end

      def condition
        @astlet.children[0]
      end

      def true_expr
        @true_expr
      end

      def false_expr
        @false_expr
      end

      def terminal?
        false
      end
    end

    class ReturnNode < Node
      def result
        @astlet.children[0]
      end

      def terminal?
        true
      end
    end
  end
end