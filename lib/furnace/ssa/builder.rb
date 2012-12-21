module Furnace::SSA
  class Builder
    attr_reader   :function
    attr_accessor :current_block

    def initialize(arguments=[], return_type=nil)
      @function = Function.new(arguments, return_type)

      entry = block
      @function.entry = entry

      @current_block = entry
    end

    def block
      block = BasicBlock.new(@function)
      @function.add block

      block
    end

    def goto(block)
      @current_block = block
    end

    def insn(instruction, *uses)
      insn = instruction.new(@current_block, uses)
      @current_block.instructions << insn

      insn.defs
    end

    def assign(value)
      result, = insn(Assign, value)
      result
    end

    def jump(block)
      insn(Jump, Immediate.new(BasicBlock, block.label))
    end

    def phi(*uses)
      result, = insn(Phi, *uses)
      result
    end

    def return(value)
      insn(Return, value)

      nil
    end

    def cond(instruction, *uses)
      switch(instruction, *uses, 2)
    end

    def switch(instruction, *uses, successor_count)
      successors = successor_count.times.map { block }

      labels = successors.map do |succ|
        Immediate.new(BasicBlock, succ.label)
      end

      insn(instruction, *uses, *labels)

      successors
    end
  end
end