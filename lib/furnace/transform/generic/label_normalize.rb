module Furnace
  module Transform
    module Generic
      class LabelNormalize
        include AST::Visitor

        def transform(ast, method)
          # Find the minimal label in each operation sub-tree.
          # It's the operation entry point.
          visit ast

          # Traverse operations in reverse order and bypass all jump_target's,
          # recording the forwarded address in label_map.
          label_map  = {}

          last_real_operation = nil
          ast.children.reverse.each do |child|
            if child.type == :jump_target
              label = last_real_operation
            else
              label = child.metadata[:label]
              last_real_operation = label
            end

            label_map[child.metadata[:label]] = label
          end

          # Remove jump_target's.
          ast.children.reject! { |c| c.type == :jump_target }

          # Find all jumpable labels and substitute the addresses to forward
          # through jump_target's.
          target_map = []

          ast.children.each do |child|
            if child.type == :jump || child.type == :jump_if
              forwarded_target  = label_map[child.children[0]]
              child.children[0] = forwarded_target

              target_map << forwarded_target
            end
          end

          [ ast, target_map, method ]
        end

        def on_any(node)
          return if node.type == :root

          child_nodes = node.children.select { |c| c.is_a? AST::Node }

          new_label = child_nodes.map { |c| c.metadata[:label] }.compact.min
          node.metadata[:label] = new_label if new_label

          child_nodes.each { |c| c.metadata.delete :label }
        end
      end
    end
  end
end