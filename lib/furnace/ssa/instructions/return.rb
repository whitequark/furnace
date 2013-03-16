module Furnace
  class SSA::ReturnInsn < SSA::TerminatorInstruction
    syntax do
    end

    def exits?
      true
    end
  end
end
