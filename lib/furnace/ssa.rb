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

  require_relative 'ssa/value'
  require_relative 'ssa/immediate'
  require_relative 'ssa/instruction'
  require_relative 'ssa/instructions/jump'
  require_relative 'ssa/instructions/assign'
  require_relative 'ssa/instructions/phi'
  require_relative 'ssa/instructions/return'
  require_relative 'ssa/basic_block'
  require_relative 'ssa/function'
  require_relative 'ssa/builder'
end