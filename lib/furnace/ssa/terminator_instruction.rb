module Furnace
  class SSA::TerminatorInstruction < SSA::Instruction
    def terminator?
      true
    end

    def exits?
      raise NotImplementedError, "reimplement SSA::TerminatorInstruction#exits? in a subclass"
    end

    def successors
      operands.
        select do |value|
          value.type == SSA::BasicBlock
        end.map do |value|
          value.name
        end
    end
  end
end