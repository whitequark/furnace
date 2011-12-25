module Furnace
  module ANF
    class Graph
      attr_reader :nodes, :root

      def initialize
        @root = nil
        @nodes = Set.new
      end

      def add(node)
        @root = node if @nodes.empty?
        @nodes.add node
      end

      def delete(node)
        @nodes.delete node
      end

      def find(label)
        @nodes.find { |node| node.label == label }
      end

      def build_apply(edge, parameters, metadata={})
        AST::Node.new(:apply, [ edge.target.label, *parameters ], metadata)
      end

      def to_graphviz
        Graphviz.new do |graph|
          @nodes.each do |node|
            graph.node node.label, node.astlet.to_sexp

            case node
            when ANF::IfNode
              graph.edge node.label, node.true_expr.target.label, "true"
              graph.edge node.label, node.false_expr.target.label, "false"
            when ANF::ApplyNode
              graph.edge node.label, node.target.label
            end
          end
        end
      end
    end
  end
end