module Furnace
  class SSA::GenericInstruction < SSA::Instruction
    attr_accessor :type

    def initialize(basic_block, type=nil, uses=[], name=basic_block.function.make_name)
      super(basic_block, uses, name)
      @type = type
    end
  end
end