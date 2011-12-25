module Furnace
  module Transform
    class ANFVariableReplacer
      include AST::Visitor

      def initializer
    end

    class ANFTransform
      def with_each_dominated_node(node)
        work_set = [ node ]
        seen_set = Set.new

        while work_set.any?
          node = work_set.shift
          seen_set.add node

          yield node

          node.leaving_edges.each do |edge|
            target = edge.target

            if target && !seen_set.include?(target)
              work_set << target
            end
          end
        end
      end

      def replace_variable(node, from, to)
      end
    end
  end
end