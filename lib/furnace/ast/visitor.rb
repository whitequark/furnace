module Furnace::AST
  module Visitor
    def visit(node)
      node.children.map! do |child|
        if child.is_a? Node
          visit child

          if child.type == :expand
            child = child.children
          end
        end

        child
      end

      node.children.flatten!

      node.children.delete_if do |child|
        if child.is_a? Node
          child.parent = node

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