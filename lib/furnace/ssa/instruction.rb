module Furnace
  class SSA::Instruction < SSA::User
    def self.opcode
      @opcode ||= SSA.class_name_to_opcode(self)
    end

    def self.syntax(&block)
      SSA::InstructionSyntax.new(self).evaluate(&block)
    end

    attr_accessor :basic_block

    def initialize(basic_block, operands=[], name=nil)
      super(basic_block.function, operands, name)
      @basic_block = basic_block
    end

    def initialize_copy(original)
      super

      @operands = nil
    end

    def name=(name)
      old_name = @name
      super
      @function.instrument { |i| i.rename(self, old_name) }
    end

    def opcode
      self.class.opcode
    end

    def remove
      @basic_block.remove self
      detach
    end

    def replace_with(value)
      replace_all_uses_with value

      if value.is_a? SSA::Instruction
        @basic_block.replace self, value
        detach
      else
        remove
      end
    end

    def replace_type_with(type, replacement)
    end

    def has_side_effects?
      false
    end

    def terminator?
      false
    end

    def awesome_print(p=AwesomePrinter.new)
      unless type == Type::Bottom.new
        p.nest(type).
          name(name).
          text('=')
      end

      p.keyword(opcode)

      pretty_parameters(p)
      pretty_operands(p)

      p
    end

    def inspect_as_value(p=AwesomePrinter.new)
      if type == Type::Bottom.new
        p.nest(type)
      else
        super
      end
    end

    def pretty_parameters(p=AwesomePrinter.new)
    end

    def pretty_operands(p=AwesomePrinter.new)
      if @operands
        p.collection('', ', ', '', @operands) do |operand|
          operand.inspect_as_value(p)
        end
      else
        p.text('<DETACHED>')
      end
    end

    protected

    def instrument_update
      @function.instrument { |i| i.update_instruction(self) }
    end
  end
end
