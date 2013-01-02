module Furnace
  class SSA::Instruction < SSA::User
    def self.opcode
      @opcode ||=
        name.split('::').last.gsub(/([a-z]|^)([A-Z])/) do
          if $1.empty?
            $2.downcase
          else
            "#{$1}_#{$2.downcase}"
          end
        end.gsub(/_insn$/, '')
    end

    attr_accessor :basic_block

    def initialize(basic_block, operands=[], name=nil)
      super(basic_block.function, operands, name)
      @basic_block = basic_block
    end

    def opcode
      self.class.opcode
    end

    def pretty_parameters(p)
    end

    def pretty_operands(p)
      p.values @operands
    end

    def pretty_print(p=SSA::PrettyPrinter.new)
      if SSA::Void != type
        p.type  type
        p.name  name
        p.text  '='
      end

      p.keyword opcode

      pretty_parameters(p)
      pretty_operands(p)
    end

    def inspect_as_value(p=SSA::PrettyPrinter.new)
      if SSA::Void != type
        super
      else
        p.type  type
      end
    end
  end
end