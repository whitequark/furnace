module Furnace
  module Transform
    module Generic
      class ANFBuild
        include AST::Visitor

        def transform(cfg, method)
          @method_locals = method.local_names

          cfg.nodes.each do |node|
            @locals = {}
            @node   = node

            # At this point we can have no more than two edges.
            @default_edge = node.default_leaving_edge
            @other_edge   = node.leaving_edge(node.operations.last.metadata[:label])

            # Transform the AST for each node, removing redundant operations.
            node.operations.delete_if do |operation|
              visit operation

              operation.type == :remove
            end

            # If a node does not have a conditional in it (i.e. it was inserted as a part
            # of SSA-induction process), add an explicit tailcall.
            if node.operations.empty?
              node.operations << node.default_leaving_edge.to_ast_node(passed_locals)
            end
          end

          [ cfg, method ]
        end

        def passed_locals
          @method_locals.map do |name|
            # Is the name rebound?
            if @locals.include?(name)
              @locals[name]
            # Is it the middle of function?
            elsif @node.entering_edges.any?
              name
            # Locals default to nil.
            else
              nil
            end
          end
        end

        # (set-local :var value) -> .
        def on_set_local(node)
          @locals[node.children.first] = node.children.last

          node.update(:remove)
        end

        # (jump-if compare_to condition) -> (if condition if_true if_false)
        def on_jump_if(node)
          if node.children.first == true
            if_true, if_false = @default_edge, @other_edge
          else
            if_true, if_false = @other_edge, @default_edge
          end

          node.update(:if, [ node.children.last,
                             if_true.to_ast_node(passed_locals),
                             if_false.to_ast_node(passed_locals) ])
        end

        def expand_node(node)
          node.update(:expand)
        end

        # Locals are immutable now.
        alias :on_get_local :expand_node

        # Immediates do not have to carry metadata anymore.
        alias :on_true :expand_node
        alias :on_false :expand_node
        alias :on_nil :expand_node
        alias :on_fixnum :expand_node
      end
    end
  end
end