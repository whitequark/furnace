module Furnace
  class SSA::PhiInsn < SSA::GenericInstruction
    def initialize(type, operands={}, name=nil)
      super(type, operands, name)
    end

    def each_operand(&block)
      return to_enum(:each_operand) if block.nil?

      if @operands
        @operands.each do |basic_block, value|
          yield basic_block
          yield value
        end
      end
    end

    def operands=(operands)
      update_use_lists do
        @operands = operands
      end
    end

    def translate_operands(map)
      Hash[@operands.map do |basic_block, value|
        [ map[basic_block], map[value] ]
      end]
    end

    protected

    def awesome_print_operands(p)
      p.collection('', ', ', '', @operands) do |basic_block, value|
        p.name(basic_block.name).
          text('=>')
        value.awesome_print_as_value p
      end
    end

    def replace_uses_of_operands(use, new_use)
      if @operands.include? use
        value = @operands[use]
        @operands.delete use
        @operands[new_use] = value

        true
      else
        found = false

        @operands.each do |basic_block, operand|
          if operand == use
            found = true
            @operands[basic_block] = new_use
          end
        end

        found
      end
    end
  end
end
