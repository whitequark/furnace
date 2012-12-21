module Furnace::SSA
  class Assign < Instruction
    def use_count
      1
    end

    def def_count
      1
    end

    def def_types
      use_types
    end
  end
end