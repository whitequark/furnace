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

    def has_side_effects?
      false
    end

    def terminator?
      false
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      unless type == SSA.void
        p.type  type
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
      if type == SSA.void
        p.type  type
      else
        super
      end
    end

    protected

    def pretty_parameters(p)
    end

    def pretty_operands(p)
      if @operands
        p.values @operands
      else
        p.text '<DETACHED>'
      end
    end
  end
end