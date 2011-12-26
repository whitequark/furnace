module Furnace
  module Transform
    module Generic
      class ANFBuild
        include AST::Visitor

        def transform(cfg, method)
          @method_locals = method.local_names

          @last_label = -1
          @anf_nodes = Hash.new { |k,v| v }
          @anf_edges = []

          @anf = ANF::Graph.new

          cfg.nodes.each do |node|
            @locals = {}
            @node   = node

            @last_anf_node = nil

            # At this point we can have no more than two edges.
            @default_edge = node.default_leaving_edge
            @other_edge   = node.leaving_edge(node.operations.last.metadata[:label])

            # Transform the AST for each node to ANF, removing redundant root nodes
            # in the process.
            node.operations.delete_if do |operation|
              visit operation

              operation.type == :remove
            end

            # If there were no nodes created, fallback to default CFG edge.
            @last_anf_node ||= @default_edge.target_label

            # If some operations were done just for side effect, add an InNode.
            if node.operations.any?
              anf_in = ANF::InNode.new(@anf, node.operations)
              @anf.nodes.add anf_in

              @anf_edges << [ anf_in, @last_anf_node ]
              @last_anf_node = anf_in
            end

            # If any locals were rebound, add a LetNode.
            if @locals.any? || node.operations.any?
              anf_let = ANF::LetNode.new(@anf, passed_locals)
              @anf.nodes.add anf_let

              @anf_edges << [ anf_let, @last_anf_node ]
              @last_anf_node = anf_let
            end

            @anf_nodes[node.label] = @last_anf_node
          end

          # The root is a CFG node with label (ip) 0.
          @anf.root = @anf_nodes[0]

          @anf_edges.each do |(source_label, target_label, param)|
            @anf.edges.add ANF::Edge.new(@anf_nodes[source_label],
                                         @anf_nodes[target_label],
                                         param)
          end

          [ @anf, method ]
        end

        def passed_locals
          map = @method_locals.map do |name|
            # Is the name rebound?
            if @locals.include?(name)
              [ name, @locals[name] ]
            # Is it the middle of function?
            elsif @node.entering_edges.any?
              [ name, AST::LocalVariable.new(name) ]
            # Locals default to nil.
            else
              [ name, nil ]
            end
          end

          Hash[*map.flatten]
        end

        # (set-lvar :var value)
        def on_set_lvar(ast_node)
          @locals[ast_node.children.first] = ast_node.children.last

          ast_node.update(:remove)
        end

        # (jump-if compare_to condition)
        def on_jump_if(ast_node)
          if ast_node.children.first == true
            true_edge, false_edge = @other_edge, @default_edge
          else
            true_edge, false_edge = @default_edge, @other_edge
          end

          true_node      = ANF::LetNode.new(@anf, passed_locals)
          false_node     = ANF::LetNode.new(@anf, passed_locals)
          @last_anf_node = ANF::IfNode.new(@anf, ast_node.children.last)

          @anf.nodes.merge [ true_node, false_node, @last_anf_node ]

          @anf_edges << [ @last_anf_node, true_node, true   ] <<
                        [ true_node,  true_edge.target_label  ]
          @anf_edges << [ @last_anf_node, false_node, false ] <<
                        [ false_node, false_edge.target_label ]

          ast_node.update(:remove)
        end

        # (return expression)
        def on_return(ast_node)
          @last_anf_node = ANF::ReturnNode.new(@anf, ast_node.children.last)

          @anf.nodes.add @last_anf_node

          ast_node.update(:remove)
        end

        # (get-lvar :x) -> %x
        def on_get_lvar(node)
          node.update(:expand, AST::LocalVariable.new(node.children.first))
        end

        # AST node labels do not make sense.
        def on_any(ast_node)
          ast_node.metadata.delete :label
        end

        def expand_node(node)
          node.update(:expand)
        end

        # Immediates do not have to carry metadata anymore.
        alias :on_true :expand_node
        alias :on_false :expand_node
        alias :on_nil :expand_node
        alias :on_fixnum :expand_node
        alias :on_literal :expand_node

        # We have a near infinite supply of small, unoccupied labels.
        def make_label
          @last_label -= 1
        end
      end
    end
  end
end