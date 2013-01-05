module Furnace
  class SSA::PhiInsn < SSA::GenericInstruction
    def initialize(basic_block, type, operands={}, name=nil)
      super(basic_block, type, operands, name)
    end

    def each_operand(&block)
      @operands.values.each &block if @operands
    end

    def operands=(operands)
      update_use_lists do
        @operands = operands
      end
    end

    def replace_uses_of(value, new_value)
      found = false

      @operands.each do |basic_block, operand|
        if operand == value
          found = true
          @operands[basic_block] = new_value
        end
      end

      if found
        value.remove_use(self)
        new_value.add_use(self)
      else
        raise ArgumentError, "#{value.inspect} is not used in #{self.inspect}"
      end

      self
    end

    def pretty_operands(p)
      @operands.each_with_index do |(basic_block, value), index|
        p.name basic_block.name
        p.text '=>'
        value.inspect_as_value p

        p << ',' if index < @operands.count - 1
      end
    end
  end
end