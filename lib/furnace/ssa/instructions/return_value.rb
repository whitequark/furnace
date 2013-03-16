module Furnace
  class SSA::ReturnValueInsn < SSA::TerminatorInstruction
    syntax do |s|
      s.operand :value
    end

    def exits?
      true
    end
  end
end
