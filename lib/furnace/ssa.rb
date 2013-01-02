module Furnace
  module SSA
    def self.inspect_type(type)
      if type
        type.inspect_as_type
      else
        '<?>'
      end
    end
  end

  require_relative 'ssa/pretty_printer'

  require_relative 'ssa/void'

  require_relative 'ssa/value'
  require_relative 'ssa/constant'
  require_relative 'ssa/named_value'
  require_relative 'ssa/argument'
  require_relative 'ssa/user'

  require_relative 'ssa/instruction'
  require_relative 'ssa/generic_instruction'

  require_relative 'ssa/instructions/phi'
  require_relative 'ssa/instructions/branch'
  require_relative 'ssa/instructions/return'

  require_relative 'ssa/basic_block'
  require_relative 'ssa/function'

  require_relative 'ssa/module'

  require_relative 'ssa/builder'
end