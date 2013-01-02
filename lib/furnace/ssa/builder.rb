module Furnace
  class SSA::Builder
    attr_reader   :function
    attr_accessor :block

    def initialize(name, arguments=[], return_type=nil)
      @function = SSA::Function.new(name, [], return_type)
      @function.arguments = arguments.map do |(type, name)|
        SSA::Argument.new(@function, type, name)
      end

      @block = @function.entry = add_block
    end

    def add_block
      block = SSA::BasicBlock.new(@function)
      @function.add block

      block
    end

    def with(block)
      old_block = @block
      @block    = block

      yield old_block
    ensure
      @block    = old_block
    end

    def insn(instruction, *uses)
      insn = instruction.new(@block, uses)
      @block.append insn

      insn
    end

    def typed_insn(instruction, type, *uses)
      insn = instruction.new(@block, type, uses)
      @block.append insn

      insn
    end

    def branch(block)
      insn(SSA::Branch, block.to_value)
    end

    def phi(type, *uses)
      typed_insn(SSA::Phi, type, *uses)
    end

    def return(value)
      insn(SSA::Return, value)

      nil
    end

    def cond(instruction, *uses)
      switch(instruction, *uses, 2)
    end

    def switch(instruction, *uses, successor_count)
      successors = successor_count.times.map { add_block }

      insn(instruction, *uses, *successors.map(&:to_value))

      @block = add_block

      successors
    end
  end
end