module Furnace::CFG
  class Graph
    attr_reader :nodes, :edges

    def initialize
      @nodes = Set.new
      @edges = Set.new

      @pending_label      = nil
      @pending_operations = []
    end

    def find_node(label)
      if node = @nodes.find { |n| n.label == label }
        node
      else
        raise "Cannot find CFG node #{label}"
      end
    end

    def expand(label, operation)
      @pending_label ||= label
      @pending_operations << operation
    end

    def transfer(targets)
      return unless @pending_label

      @nodes << Node.new(self, @pending_label, @pending_operations)

      targets.each do |operation, target|
        @edges << Edge.new(self, operation, @pending_label, target)
      end

      @pending_label      = nil
      @pending_operations = []
    end

    def to_graphviz
      Furnace::Graphviz.new do |graph|
        @nodes.each do |node|
          graph.node node.label, node.operations.map(&:inspect).join("\n")
        end

        @edges.each do |edge|
          if edge.source_operation.nil?
            label = "~"
          else
            label = edge.source_operation
          end

          graph.edge edge.source_label, edge.target_label, label
        end
      end
    end
  end
end