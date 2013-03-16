module Furnace
  class SSA::ReturnValueInsn < SSA::ReturnInsn
    syntax do |s|
      s.operand :value
    end

    def value_type
      value.type
    end
  end
end
