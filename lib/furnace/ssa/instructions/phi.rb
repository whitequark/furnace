module Furnace::SSA
  class Phi < Instruction
    def use_count
      nil
    end

    def def_count
      1
    end
  end
end