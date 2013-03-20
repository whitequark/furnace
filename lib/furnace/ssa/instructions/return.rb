module Furnace
  class SSA::ReturnInsn < SSA::TerminatorInstruction
    def value_type
      Type::Bottom.new
    end

    def exits?
      true
    end
  end
end
