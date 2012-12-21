module Furnace::SSA
  class Return < Instruction
    def use_count
      1
    end
  end
end