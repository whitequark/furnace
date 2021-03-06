module Furnace
  module SSA
    def self.class_name_to_opcode(klass)
      klass.to_s.split('::').last.
        gsub(/([A-Z])/) { '_' + $1.downcase }.
        gsub(/^_(.+)_insn$/, '\1')
    end

    def self.opcode_to_class_name(opcode)
      opcode.to_s.gsub(/(?:([a-z])_|^)([a-z])/) do
        if $1.nil?
          $2.upcase
        else
          "#{$1}#{$2.upcase}"
        end
      end + 'Insn'
    end
  end

  require_relative 'ssa/event_stream'
  require_relative 'ssa/instrumentation'

  require_relative 'ssa/types/basic_block'
  require_relative 'ssa/types/function'

  require_relative 'ssa/value'
  require_relative 'ssa/constant'
  require_relative 'ssa/named_value'
  require_relative 'ssa/argument'
  require_relative 'ssa/user'

  require_relative 'ssa/instruction'
  require_relative 'ssa/instruction_syntax'
  require_relative 'ssa/generic_instruction'
  require_relative 'ssa/terminator_instruction'

  require_relative 'ssa/basic_block'
  require_relative 'ssa/function'

  require_relative 'ssa/instructions/phi'
  require_relative 'ssa/instructions/branch'
  require_relative 'ssa/instructions/return'
  require_relative 'ssa/instructions/return_value'

  require_relative 'ssa/module'

  require_relative 'ssa/builder'
end
