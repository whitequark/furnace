module Furnace
  module Transform
    module Optimizing
      class FoldConstants
        def transform(anf, method)
          anf.nodes.each do |node|
            if node.is_a? ANF::LetNode
              node.try_propagate
              node.try_eliminate
            end
          end
          anf.eliminate_dead_code

          [ anf, method ]
        end
      end
    end
  end
end