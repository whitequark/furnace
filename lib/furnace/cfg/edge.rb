module Furnace
  module CFG
    class Edge
      attr_accessor :source_operation, :source_label, :target_label

      def initialize(cfg, source_operation, source_label, target_label)
        @cfg, @source_operation, @source_label, @target_label =
            cfg, source_operation, source_label, target_label
      end

      def source
        @cfg.find_node(@source_label)
      end

      def target
        @cfg.find_node(@target_label) if @target_label
      end

      def source=(node)
        @source_label = node.label
      end

      def target=(node)
        if node
          @target_label = node.label
        else
          @target_label = nil
        end
      end

      def to_ast_node(parameters)
        AST::ApplyNode.new(@target_label, parameters)
      end

      def inspect
        "<#{@source_label.inspect} -> #{@target_label.inspect}>"
      end
    end
  end
end