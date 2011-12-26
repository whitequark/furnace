module Furnace
  module Transform
    module Generic
      class VariableTracer
        include AST::Visitor

        attr_reader :read_set, :write_set

        def initialize
          @read_set  = Set.new
          @write_set = Set.new
          @conflict  = false
        end

        def reset
          @read_set.clear
          @write_set.clear
          @conflict = false
        end

        def conflict?
          @conflict
        end

        def on_set_lvar(node)
          var = node.children.first

          @write_set.add var
          @conflict ||= @read_set.include?(var)
        end

        def on_get_lvar(node)
          var = node.children.first

          @read_set.add var
          @conflict ||= @write_set.include?(var)
        end
      end

      class CFGBuild
        def transform(ast, target_map, method)
          cfg = CFG::Graph.new

          tracer = VariableTracer.new

          ast.children.each do |child|
            label = child.metadata[:label]

            # Transfer control to the next operation directly if this
            # is a jump target.
            if target_map.include? label
              cfg.transfer({ nil => label })
            end

            # Our CFG must also be easily convertible to ANF/SSA.
            # Split blocks if a non-SSA variable operation is encountered.
            tracer.visit child

            if tracer.conflict?
              cfg.transfer({ nil => child.metadata[:label] })
            end

            # Expand current operation.
            cfg.expand label, child

            # Transfer control non-sequentaly if needed.
            if child.type == :jump
              cfg.transfer({ label => child.children[0] })
            elsif child.type == :jump_if
              cfg.transfer({ label => child.children[0],
                             nil   => child.next.metadata[:label] })
            elsif child.type == :return
              cfg.transfer({ })
            elsif tracer.conflict?
              # Reset tracer below.
            else
              next
            end

            # There was a conflict or a control transfer. Reset the tracer.
            tracer.reset
          end

          [ cfg, method ]
        end
      end
    end
  end
end