module Furnace
  class SSA::GenericInstruction < SSA::Instruction
    attr_reader :type

    def initialize(basic_block, type=nil, uses=[], name=basic_block.function.make_name)
      super(basic_block, uses, name)
      self.type = type
    end

    def type=(type)
      @type = type.to_type if type
    end
  end
end