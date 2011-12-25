module Furnace
  module Transform
    module Generic
      class CFGBuild
        def transform(ast, target_map)
          cfg = CFG::Graph.new

          ast.children.each do |child|
            label = child.metadata[:label]

            # Transfer control to the next operation directly if this
            # is a jump target.
            if target_map.include? label
              cfg.transfer({ nil => label })
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
              cfg.transfer({ label => nil })
            end
          end

          [ cfg ]
        end
      end
    end
  end
end