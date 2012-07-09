module Furnace::AST
  module Visitor
    def visit(node)
      replacements = {}

      node.children.each_with_index do |child, index|
        if child.is_a? Node
          visit child

          if child.type == :expand
            replacements[index] = child.children
          end
        end
      end

      if replacements.any?
        new_children = []

        node.children.each_with_index do |child, index|
          if replacements[index]
            new_children.concat replacements[index]
          else
            new_children.push child
          end
        end

        node.children.replace new_children
      end

      node.children.delete_if do |child|
        if child.is_a? Node
          child.type == :remove
        end
      end

      # Invoke a specific handler
      on_handler = :"on_#{node.type}"
      if respond_to? on_handler
        send on_handler, node
      end

      # Invoke a generic handler
      if respond_to? :on_any
        send :on_any, node
      end

      node
    end
  end
end