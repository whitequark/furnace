module Furnace
  class SSA::Instruction < SSA::User
    def self.opcode
      @opcode ||= SSA.class_name_to_opcode(self)
    end

    def self.syntax(&block)
      SSA::InstructionSyntax.new(self).evaluate(&block)
    end

    attr_reader :basic_block

    def opcode
      self.class.opcode
    end

    def basic_block=(basic_block)
      if @basic_block && @basic_block != basic_block
        @basic_block.remove self
      end

      if basic_block
        self.function = basic_block.function
      end

      @basic_block = basic_block

      SSA.instrument(self)
    end

    def detach
      @basic_block = nil

      super
    end

    def remove
      @basic_block.remove self if @basic_block
    end

    def erase
      remove
      drop_references
    end

    def replace_with(value)
      replace_all_uses_with value

      if value.is_a? SSA::Instruction
        @basic_block.replace self, value
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

      awesome_print_parameters(p)
      awesome_print_operands(p)

      p
    end

    def awesome_print_as_value(p=AwesomePrinter.new)
      if type == Type::Bottom.new
        p.nest(type)
      else
        super
      end
    end

    def awesome_print_parameters(p=AwesomePrinter.new)
      p
    end

    def awesome_print_operands(p=AwesomePrinter.new)
      if @operands
        p.collection('', ', ', '', @operands) do |operand|
          operand.awesome_print_as_value(p)
        end
      else
        p.text('<DETACHED>')
      end
    end

    protected :function=
  end
end
