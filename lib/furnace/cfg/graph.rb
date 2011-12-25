module Furnace
  module CFG
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

        @nodes << CFG::Node.new(self, @pending_label, @pending_operations)

        targets.each do |operation, target|
          @edges << CFG::Edge.new(self, operation, @pending_label, target)
        end

        @pending_label      = nil
        @pending_operations = []
      end

      def to_graphviz
        code = "digraph {\n"
        code << "node [labeljust=l,nojustify=true,fontname=monospace];"
        code << "rankdir=LR;"
        code << "K=1;"

        code << "lexit [label=EXIT];\n";

        @nodes.each do |node|
          content = node.operations.map(&:to_sexp).join("\n")
          content.gsub!(">", "&gt;")
          content.gsub!("<", "&lt;")
          content = content.lines.map { |l| %Q{<tr><td align="left">#{l}</td></tr>} }.join

          code << %Q{l#{node.label} [shape=box,label=<<table border="0">#{content}</table>>];\n}
        end

        @edges.each do |edge|
          label = edge.source_operation || "~"

          code << %Q{l#{edge.source_label} -> l#{edge.target_label || 'exit'} [label="#{label}"];\n}
        end

        code << "}"

        code
      end
    end
  end
end