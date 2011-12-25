module Furnace
  module AST
    module Visitor
      def visit(node, options={})
        node.children.map! do |child|
          if child.is_a? Node
            visit child, options

            # Invoke a specific handler
            on_handler = :"on_#{child.type}"
            if respond_to? on_handler
              send on_handler, child
            end

            # Invoke a generic handler
            if respond_to? :on_any
              send :on_any, child
            end

            # Normalize the tree, as nodes can only update themselves
            if options[:normalize]
              if child.type == :expand
                child = child.children
              elsif child.type == :remove
                child = nil
              end
            end
          end

          child
        end

        node.children.flatten!
        node.children.compact!

        node.children.each do |child|
          if child.is_a? Node
            child.parent = node
          end
        end

        node
      end
    end
  end
end