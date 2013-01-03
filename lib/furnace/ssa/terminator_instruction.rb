module Furnace
  class SSA::TerminatorInstruction < SSA::Instruction
    def terminator?
      true
    end

    def exits?
      raise NotImplementedError, "reimplement SSA::TerminatorInstruction#exits? in a subclass"
    end
  end
end