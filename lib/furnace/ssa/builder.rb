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

    def append(instruction, *args)
      insn = instruction.new(@block, *args)
      @block.append insn

      insn
    end

    def phi(type, mapping)
      append(SSA::Phi, type, Hash[mapping])
    end

    def branch(post_block)
      old_block = @block
      @block    = add_block

      value     = yield old_block

      append(SSA::Branch, [ post_block ])

      [ @block, value ]
    ensure
      @block    = old_block
    end

    def control_flow_op(instruction, type=nil, uses)
      cond_block = @block
      post_block = add_block

      mapping = yield post_block

      targets = mapping.map { |(target, _)| target }
      append(instruction, uses + targets)

      @block = post_block
      phi(type, mapping.map do |(target, value)|
                  if target == post_block
                    [cond_block, value]
                  else
                    [target, value]
                  end
                end)
    end

    def return(value)
      append(SSA::Return, [ value ])
    end
  end
end