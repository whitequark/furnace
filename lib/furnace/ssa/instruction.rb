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

    def pretty_print(p=SSA::PrettyPrinter.new)
      unless type == Type::Bottom.new
        type.pretty_print(p)
        p.name  name
        p.text  '='
      end

      if valid?
        p.keyword opcode
      else
        p.keyword_invalid opcode
      end

      pretty_parameters(p)
      pretty_operands(p)

      p
    end

    def inspect_as_value(p=SSA::PrettyPrinter.new)
      if type == Type::Bottom.new
        type.pretty_print(p)
      else
        super
      end
    end

    def pretty_parameters(p=SSA::PrettyPrinter.new)
    end

    def pretty_operands(p=SSA::PrettyPrinter.new)
      if @operands
        p.values @operands
      else
        p.text '<DETACHED>'
      end
    end

    protected

    def instrument_update
      @function.instrument { |i| i.update_instruction(self) }
    end
  end
end
