module Furnace::AST
  module StrictVisitor
    def visit(node)
      # Invoke a specific handler
      on_handler = :"on_#{node.type}"
      if respond_to? on_handler
        new_node = send on_handler, node
        node = new_node if new_node
      end

      node
    end

    def visit_all(nodes)
      nodes.map do |node|
        visit node
      end
    end
  end
end