module Furnace
  module ANF
    class Node
      attr_reader :graph

      def initialize(graph)
        @graph = graph
      end

      def leaving_edges
        @graph.edges.select { |edge| edge.source == self }
      end

      def leaving_edge(param=nil)
        @graph.edges.find   { |edge| edge.source == self && edge.param == param }
      end

      def entering_edges
        @graph.edges.select { |edge| edge.target == self }
      end

      def humanize(node)
        if node.respond_to? :to_sexp
          node.to_sexp
        else
          node.inspect
        end
      end
    end
  end
end