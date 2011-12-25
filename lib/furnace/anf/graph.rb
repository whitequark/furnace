module Furnace
  module ANF
    class Graph
      attr_reader :nodes, :root

      def initialize
        @root       = nil
        @nodes      = Set.new
        @last_label = 0
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

      def build_apply(edge, parameters, label=make_label)
        ast_node = AST::Node.new(:apply, [ edge.target.label, *parameters ])

        add ANF::ApplyNode.new(self, ast_node, label)

        label
      end

      def make_label
        @last_label -= 1
      end

      def to_graphviz
        Graphviz.new do |graph|
          @nodes.each do |node|
            graph.node node.label, node.astlet.to_sexp

            case node
            when ANF::IfNode
              graph.edge node.label, node.true_target.label, "true"
              graph.edge node.label, node.false_target.label, "false"
            when ANF::ApplyNode
              graph.edge node.label, node.target.label
            end
          end
        end
      end
    end
  end
end