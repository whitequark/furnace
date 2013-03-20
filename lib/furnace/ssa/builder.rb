module Furnace
  class SSA::Builder
    attr_reader   :function
    attr_accessor :block

    def self.scope
      SSA
    end

    def initialize(name, arguments=[], return_type=nil, options={})
      if options[:instrument]
        instrumentation = SSA::EventStream.new
      end

      @function = SSA::Function.new(name, [], return_type, instrumentation)
      @function.arguments = arguments.map do |(type, name)|
        SSA::Argument.new(type, name)
      end

      @block = @function.entry = add_block
    end

    def lookup_insn(opcode)
      self.class.scope.const_get SSA.opcode_to_class_name(opcode)
    end

    def add_block
      block = SSA::BasicBlock.new
      @function.add block

      if block_given?
        branch block
        @block = block

        yield
      else
        block
      end
    end

    def append(instruction, *args)
      insn = lookup_insn(instruction).new(*args)
      @block.append insn

      insn
    end

    def branch(target)
      append(:branch, [ target ])
    end

    def phi(type, mapping)
      append(:phi, type, Hash[mapping])
    end

    def fork(post_block)
      old_block = @block
      new_block = add_block

      @block    = new_block

      value     = yield old_block

      branch post_block

      [ new_block, value ]
    ensure
      @block    = old_block
    end

    def control_flow_op(instruction, type=Type::Variable.new, uses)
      cond_block = @block
      post_block = add_block

      mapping = yield cond_block, post_block

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

    def return
      append(:return)
    end

    def return_value(value)
      append(:return_value, [ value ])
    end

    def method_missing(opcode, *args)
      class_name = SSA.opcode_to_class_name(opcode)

      if self.class.scope.const_defined? class_name
        append opcode, *args
      else
        super
      end
    end
  end
end
