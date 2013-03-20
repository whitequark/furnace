module Furnace
  class SSA::NamedValue < SSA::Value
    attr_accessor :function
    attr_reader   :name

    def initialize(function, name)
      super()

      @function = function
      self.name = name
    end

    def name=(name)
      @name = @function.make_name(name)
    end

    def inspect_as_value(p=AwesomePrinter.new)
      p.name(@name)
    end

    def inspect
      awesome_print
    end
  end
end
