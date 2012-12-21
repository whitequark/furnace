module Furnace
  module SSA
    def self.inspect_type(type)
      if type
        if type.respond_to? :inspect_as_type
          type.inspect_as_type
        else
          type.inspect
        end
      else
        '<?>'
      end
    end
  end

  require_relative 'ssa/value'
  require_relative 'ssa/immediate'
  require_relative 'ssa/instruction'
  require_relative 'ssa/basic_block'
  require_relative 'ssa/function'
end