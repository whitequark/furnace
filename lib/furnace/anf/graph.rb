module Furnace
  module ANF
    class Graph
      attr_reader   :nodes, :edges
      attr_accessor :root

      def initialize
        @root  = nil
        @nodes = Set.new
        @edges = Set.new
      end

      def find(label)
        @nodes.find { |node| node.label == label }
      end

      def eliminate_dead_code
        live_set = search
        @nodes  &= live_set
      end

      def search
        seen_set = Set.new
        work_set = Set.new

        work_set.add @root

        while work_set.any?
          node = work_set.first
          work_set.delete node
          seen_set.add node

          yield node if block_given?

          node.leaving_edges.map(&:target).each do |target|
            work_set.add target unless seen_set.include? target
          end
        end

        seen_set
      end

      def to_graphviz
        Graphviz.new do |graph|
          @nodes.each do |node|
            graph.node node.object_id, node.to_human_readable

            case node
            when ANF::IfNode
              graph.edge node.object_id, node.leaving_edge(true).target.object_id, "true"
              graph.edge node.object_id, node.leaving_edge(false).target.object_id, "false"
            when ANF::LetNode, ANF::InNode
              graph.edge node.object_id, node.leaving_edge.target.object_id
            end
          end
        end
      end
    end
  end
end