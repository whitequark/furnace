module Furnace
  class SSA::TerminatorInstruction < SSA::Instruction
    def terminator?
      true
    end

    def has_side_effects?
      exits?
    end

    def exits?
      raise NotImplementedError, "reimplement #{self.class}#exits?"
    end

    def successors
      operands.
        select do |value|
          value.type == SSA::BasicBlockType.new
        end.map do |value|
          value.name
        end
    end
  end
end
