module Furnace
  class SSA::ReturnInsn < SSA::TerminatorInstruction
    syntax do
    end

    def value_type
      Type::Bottom.new
    end

    def exits?
      true
    end
  end
end
