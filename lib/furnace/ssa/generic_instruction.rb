module Furnace
  class SSA::GenericInstruction < SSA::Instruction
    attr_reader :type

    def initialize(basic_block, type=nil, uses=[], name=basic_block.function.make_name)
      @type = type.to_type

      super(basic_block, uses, name)
    end

    def type=(type)
      @type = type.to_type

      instrument_update
    end

    def replace_type_with(type, replacement)
      self.type = self.type.replace_type_with(type, replacement)
    end
  end
end
