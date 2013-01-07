module Furnace
  class SSA::TerminatorInstruction < SSA::Instruction
    def has_side_effects?
      true
    end

    def terminator?
      true
    end

    def exits?
      raise NotImplementedError, "reimplement SSA::TerminatorInstruction#exits? in a subclass"
    end

    def successors
      operands.
        select do |value|
          value.type == SSA::BasicBlockType.instance
        end.map do |value|
          value.name
        end
    end
  end
end