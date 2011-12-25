module Furnace
  module CFG
    class Node
      attr_reader :label, :operations

      def initialize(cfg, label, operations)
        @cfg, @label, @operations = cfg, label, operations
      end

      def entering_edges
        @cfg.edges.select { |e| e.target == self }
      end

      def leaving_edges
        @cfg.edges.select { |e| e.source == self }
      end

      def leaving_edge(source=nil)
        leaving_edges.find { |e| e.source_operation == source }
      end

      def ==(other)
        self.label == other.label
      end

      def inspect
        if @label
          "<#{@label}:#{@operations.map(&:inspect).join ", "}>"
        else
          "<!exit>"
        end
      end
    end
  end
end