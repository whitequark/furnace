module Furnace
  class SSA::NamedValue < SSA::Value
    attr_reader :function
    attr_reader :name

    def initialize(function, name)
      super()

      @function = function
      self.name = name
    end

    def name=(name)
      @name = @function.make_name(name)
    end

    def inspect_as_value(p=SSA::PrettyPrinter.new)
      p.name name
    end

    def inspect
      pretty_print
    end
  end
end