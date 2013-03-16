module Furnace
  class SSA::TerminatorInstruction < SSA::Instruction
    def has_side_effects?
      true
    end

    def terminator?
      true
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
