module Furnace
  class SSA::GenericInstruction < SSA::Instruction
    attr_reader :type

    def initialize(type, operands=[], name=nil)
      super(operands, name)

      self.type = type
    end

    def type=(type)
      @type     = type.to_type

      instrument { |i| i.update_instruction(self) }
    end

    def replace_type_with(type, replacement)
      self.type = self.type.replace_type_with(type, replacement)
    end
  end
end
