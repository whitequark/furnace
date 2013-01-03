module Furnace
  class SSA::BranchInsn < SSA::TerminatorInstruction
    syntax do |s|
      s.operand :target, SSA::BasicBlock
    end

    def exits?
      false
    end
  end
end