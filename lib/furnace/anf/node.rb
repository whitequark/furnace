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

      def arms
        [ target ]
      end

      def terminal?
        false
      end
    end

    class IfNode < Node
      def condition
        @astlet.children[0]
      end

      def true_target
        @graph.find(@astlet.children[1])
      end

      def false_target
        @graph.find(@astlet.children[2])
      end

      def arms
        [ true_target, false_target ]
      end

      def terminal?
        false
      end
    end

    class ReturnNode < Node
      def result
        @astlet.children[0]
      end

      def arms
        [ ]
      end

      def terminal?
        true
      end
    end
  end
end