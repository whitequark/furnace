module Furnace::AST
  module StrictVisitor
    def visit(node)
      if node
        # Invoke a specific handler
        on_handler = :"on_#{node.type}"
        if respond_to? on_handler
          new_node = send on_handler, node
        else
          new_node = handler_missing(node)
        end

        node = new_node if new_node
      end

      node
    end

    def visit_all(nodes)
      nodes.map do |node|
        visit node
      end
    end

    def handler_missing(node)
    end
  end
end