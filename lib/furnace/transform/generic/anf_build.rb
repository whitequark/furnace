module Furnace
  module Transform
    module Generic
      class ANFBuild
        include AST::Visitor

        def transform(cfg, method)
          @method_locals = method.local_names
          @anf = ANF::Graph.new

          cfg.nodes.each do |node|
            @locals = {}
            @node   = node

            # At this point we can have no more than two edges.
            @default_edge = node.default_leaving_edge
            @other_edge   = node.leaving_edge(node.operations.last.metadata[:label])

            # Transform the AST for each node to ANF, removing redundant root nodes
            # in the process.
            node.operations.delete_if do |operation|
              visit operation

              operation.type == :remove
            end

            # If nothing is left, make it an application.
            if node.operations.empty?
              @anf.build_apply(@default_edge, passed_locals, node.label)
            end
          end

          [ @anf, method ]
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
        def on_set_local(ast_node)
          @locals[ast_node.children.first] = ast_node.children.last

          ast_node.update(:remove)
        end

        # (jump-if compare_to condition) -> (if condition if_true if_false)
        def on_jump_if(ast_node)
          if ast_node.children.first == true
            true_edge, false_edge = @other_edge, @default_edge
          else
            false_edge, true_edge = @default_edge, @other_edge
          end

          true_label  = @anf.build_apply(true_edge, passed_locals)
          false_label = @anf.build_apply(false_edge, passed_locals)

          ast_node.update(:if, [ ast_node.children.last, true_label, false_label ])

          @anf.add ANF::IfNode.new(@anf, ast_node, @node.label)
        end

        # (return expression)
        def on_return(ast_node)
          @anf.add ANF::ReturnNode.new(@anf, ast_node, @node.label)
        end

        # AST node labels do not make sense.
        def on_any(ast_node)
          ast_node.metadata.delete :label
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