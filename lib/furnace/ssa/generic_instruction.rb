module Furnace
  class SSA::GenericInstruction < SSA::Instruction
    attr_reader :type

    def initialize(type, operands=[], name=nil)
      @type = type.to_type

      super(operands, name)
    end

    def type=(type)
      @type     = type.to_type

      SSA.instrument(self)
    end

    def replace_type_with(type, replacement)
      self.type = self.type.replace_type_with(type, replacement)
    end
  end
end
