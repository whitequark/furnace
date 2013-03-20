module Furnace
  class SSA::BranchInsn < SSA::TerminatorInstruction
    syntax do |s|
      s.operand :target
    end

    def exits?
      false
    end
  end
end
