module Furnace
  module Transform
    module Generic
      class CFGNormalize
        def transform(cfg, method)
          cfg.nodes.each do |node|
            # If a last operation is an unconditional jump, optimize it out.
            last = node.operations.last
            if last.type == :jump
              edge = node.leaving_edge(last.metadata[:label])

              node.operations.delete last

              cfg.edges.delete edge
              cfg.edges.add CFG::Edge.new(cfg, nil, node.label, edge.target.label)
            end

            # Remove no-ops.
            node.operations.delete_if { |op| op.type == :nop }
          end

          # Remove empty nodes.
          cfg.nodes.delete_if do |node|
            if node.operations.empty?
              node.entering_edges.each do |edge|
                edge.target = node.default_leaving_edge.target
              end
              cfg.edges.subtract node.leaving_edges

              true
            else
              false
            end
          end

          [ cfg, method ]
        end
      end
    end
  end
end